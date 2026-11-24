module Basic

  ## DGRP3: files of tmp/<md5>/ that belong to the correlation analysis (kept when a user GWAS is recomputed)
  CORRELATION_FILES = /\A(output\.json|output\.err|output\..+\.tsv|dataset_sum\.json|h_correlation_res\.json|release\.txt)\z/

  ## phenotype mean matrix published with each release (see lib/tasks/create_export.rake)
  MEAN_DATA_FILE = 'all_phenotype_mean_data.tsv'
  ## name of the release whose data was used to compute the results of a tmp/<md5>/ or tmp/correlations/<md5>/ directory
  RELEASE_STAMP_FILE = 'release.txt'
  ## files kept when results are recomputed for a new release (summary of the user's own data)
  RELEASE_INDEPENDENT_FILES = ['dataset_sum.json']

  class << self

    ## DGRP3: user GWAS results computed before the switch used the DGRP2 genotypes on dm3: their variant IDs are not
    ## in the snps table anymore (or point to another variant). Their GWAS files are moved to tmp/<md5>/dgrp2_dm3/ and
    ## the <md5>.tmp input is touched, so that the run_gwas worker recomputes them on DGRP3 (it picks the md5s that
    ## have no gwas_output.json, oldest .tmp first). Returns true if the results were requeued.
    def requeue_legacy_user_gwas(output_dir)
      output_dir = Pathname.new(output_dir)
      gwas_output_file = output_dir + 'gwas_output.json'
      tmp_file = output_dir.dirname + "#{output_dir.basename}.tmp"
      ## 'done' is written when the run is over: never touch a run in progress
      return false if !File.exist?(gwas_output_file) or !File.exist?(output_dir + 'done') or !File.exist?(tmp_file)
      content = File.read(gwas_output_file)
      ## runs that stopped before choosing a genotype file (input errors) are not genotype-dependent
      return false if !content.include?('"genotype_file"') or content.include?('dgrp3.gwas')

      archive_dir = output_dir + 'dgrp2_dm3'
      FileUtils.mkdir_p(archive_dir)
      files = Dir.children(output_dir).select{|f| File.file?(output_dir + f) and !f.match?(CORRELATION_FILES)}
      ## gwas_output.json and done last: the worker only requeues the md5 once gwas_output.json is gone
      (files - ['gwas_output.json', 'done'] + ['done', 'gwas_output.json']).each do |f|
        begin
          File.rename(output_dir + f, archive_dir + f)
        rescue Errno::ENOENT ## already moved by a concurrent request
        end
      end
      FileUtils.touch(tmp_file)
      true
    end

    ## release whose data new results are computed with
    def current_release
      Release.latest_with_file(MEAN_DATA_FILE)
    end

    ## true if the results of output_dir were computed with another release than the current one
    ## (results without a stamp predate release tracking and are stale too)
    def stale_results?(output_dir, release = current_release)
      output_dir = Pathname.new(output_dir)
      return false if release.nil? or !output_dir.directory?
      stamp_file = output_dir + RELEASE_STAMP_FILE
      !(stamp_file.file? and stamp_file.read.strip == release.name)
    end

    ## Deletes the release-dependent results of output_dir (correlations and GWAS) so that they are recomputed:
    ## compute_correlation reruns the correlation, then the run_gwas worker picks the md5 again (it needs output.json
    ## and no gwas_output.json). Returns true if the results were removed.
    def clear_stale_results(output_dir, release = current_release)
      output_dir = Pathname.new(output_dir)
      return false if !stale_results?(output_dir, release)
      ## never touch a GWAS in progress ('done' is written when the run is over); retried at the next view
      return false if File.exist?(output_dir + 'gwas_output.json') and !File.exist?(output_dir + 'done')
      files = Dir.children(output_dir).select{|f| File.file?(output_dir + f)} - RELEASE_INDEPENDENT_FILES
      ## output.json first (the worker stops considering the md5), gwas_output.json last
      (['output.json'] + (files - ['output.json', 'gwas_output.json']) + ['gwas_output.json']).each do |f|
        File.delete(output_dir + f) if files.include?(f)
      rescue Errno::ENOENT ## already removed by a concurrent request
      end
      true
    end

    ## Recomputes the results of a user upload (tmp/<md5>/) if they come from an older release: the correlation
    ## from the saved <md5>.tmp input (h_correlation_res.json is rewritten), the GWAS through the run_gwas worker.
    def refresh_user_results(output_dir)
      output_dir = Pathname.new(output_dir)
      tmp_file = output_dir.dirname + "#{output_dir.basename}.tmp"
      release = current_release
      return false if !tmp_file.file? or !stale_results?(output_dir, release)
      t_header, content = File.read(tmp_file).split("\n", 2)
      content ||= ''
      ## the directory is named by the digest of the data: recompute only from the matching input
      return false if Digest::SHA256.hexdigest(content) != output_dir.basename.to_s
      h_res = compute_correlation(t_header.split("\t"), content, output_dir.dirname)
      return false if h_res[:cmd].nil?
      File.write(output_dir + 'h_correlation_res.json', h_res.to_json)
      FileUtils.touch(tmp_file) ## the worker runs the oldest .tmp first
      true
    end

    def compute_correlation t_header, content, tmp_dir #, pheno_name

      h_res = {}

      md5 = Digest::SHA256.hexdigest content
      data_dir = Pathname.new(APP_CONFIG[:data_dir])
#      Dir.mkdir(data_dir + "tmp" + "correlations") if File.exist?(data_dir + "tmp" + "correlations")
      tmp_file = tmp_dir + "#{md5}.tmp"
      output_dir = tmp_dir + md5
      
      ## phenotype mean matrix from the latest release; results of an older release are recomputed
      release = current_release
      export_mean_file = release && release.download_directory.join(MEAN_DATA_FILE)
      clear_stale_results(output_dir, release)
      cmd = nil
      t_header[0] = 'DGRP'
      if !File.exist? tmp_file
#        Dir.mkdir(output_dir) if !File.exist? output_dir
        File.open(tmp_file, 'w') do |f|
          f.write(t_header.join("\t") + "\n" )
          f.write(content)
        end
      end

      plink_file = data_dir + 'dgrp2.filtered.fastlmm'
      cov_file = data_dir + "dgrp.cov.tsv"
      annot_file = data_dir + "dgrp.fb557.annot.txt.gz"
     
      #      cmd = "Rscript running_GWAS_user.R #{tmp_file} #{plink_file} #{cov_file} #{annot_file} #{output_dir} 2 0.2 0.05 1> #{output_dir + "gwas_output.json"} 2> #{output_dir + "gwas_output.err"}"
      
      #      if !File.exist? output_dir
      output_json = output_dir + 'output.json'

      ## output.json is missing for a new upload or after clear_stale_results
      if export_mean_file and !File.exist? output_json
        FileUtils.mkdir_p output_dir
        ## stamp first, so that a concurrent request does not see a run in progress as stale
        File.write(output_dir + RELEASE_STAMP_FILE, release.name + "\n")
        cmd = "java -jar ./lib/DGRPool-1.0.jar AllCorrelations --pheno #{tmp_file} --phenodb #{export_mean_file} -o #{output_dir} 1> #{output_dir + 'output.json'} 2> #{output_dir + 'output.err'}"
        res = `#{cmd}`
      end
        #      end
        #      File.delete tmp_file if File.exist? tmp_file

      h_output = {}
      if File.exist? output_json
        h_output = Basic.safe_parse_json(File.read(output_json), {}) 
      end
      list_sex = h_output['which_sex']
      res = {} #{"M":'bla'}
      header = []
      if list_sex
        list_sex.each do |s|
          output_file = output_dir + "output.#{s}.tsv"
          res[s] = output_file
          if File.exist? output_file
            res[s] = File.read(output_file).split("\n").map{|e| e.split("\t")}.select{|e| e.last != "0"}
            header = res[s].shift
          end
        end
      end
      
      h_res = {
        :md5 => md5,
        :cmd => cmd,
        :output_dir => output_dir,
        :output_json => output_json, 
        :h_output => h_output, 
        :res => res,
        :header => header
      }
      
      return h_res
      
    end

    
    def safe_parse_json json, default
      h = default
      begin
        h = JSON.parse json
      rescue
      end
      return h
    end

    def create_key model, n
      tmp_key = Array.new(n){[*'0'..'9', *'a'..'z'].sample}.join
      if model
        while model.where(:key => tmp_key).count > 0
          tmp_key = Array.new(n){[*'0'..'9', *'a'..'z'].sample}.join
        end
      end
      return tmp_key
    end

    def is_numeric_vector v
      numeric = true
      v.compact.each do |e|
##        puts e.is_a? Numeric
        if !e.is_a? Numeric #Float or e.is_a? !e.match(/^\-?\d*\.?\d*$/)
          numeric = false
          break
        end
      end
      return numeric
    end

    def mean(t)
      sum=0
      t.select{|e| e}.each do |e|
        sum+=e.to_f
      end
      return (t.size > 0) ? sum.to_f/t.size : nil
    end

    def median(t1)
      t=t1.select{|e| e}.map{|e| e.to_f}.sort
      n=t.size
      if (n >0)
        if (n%2 == 0)
          return mean([t[(n/2)-1], t[n/2]])
        else
          # puts n/2                                                                                                                                                                                    
          return t[n/2]
        end
      else
        return nil
      end
    end

    def lss(t)
      return t.sum(0.0) { |e| (e.to_f - mean(t)) ** 2 }
    end
    
    def variance(t)
      return lss(t) / (t.size - 1)
      #  m = mean(t)
      #  sum = 0.0
      #  t.each {|v| sum += (v-m)**2 }
      #  return  sum/t.size
    end

    def std_dev(t)
      return Math.sqrt(variance(t))
    end

    def std_err(t)
      return std_dev(t) / Math.sqrt(t.size.to_f)
    end
    
    def cv(t)
      return std_dev(t) / mean(t) * 100
    end
    
    def upd_sums study

      h_sums = {:mean => {}, :median => {}, :all => {}}
      h_pheno = Basic.safe_parse_json(study.pheno_json, {})

      h_sex = {}
#      sex_list = []
      if h_pheno["summary"]
        h_pheno["summary"].each_key do |dgrp_line|
          h_pheno["summary"][dgrp_line]['sex'].each do |s|
            h_sex[s] = 1
          end
        end
      end
      if h_pheno["raw"]
        h_pheno["raw"].each_key do |dataset_id|
          h_pheno["raw"][dataset_id].each_key do |dgrp_line|
            h_pheno["raw"][dataset_id][dgrp_line]['sex'].each do |s|
              h_sex[s] = 1
            end
          end
        end
      end

      list_sex = h_sex.keys.sort
      
      if h_pheno["summary"]
        h_sums = upd_dataset_sums(study.id, nil, h_pheno["summary"], h_sums, list_sex, nil)
      end
      if h_pheno["raw"]
        h_pheno["raw"].each_key do |dataset_id|
          h_sums = upd_dataset_sums(study.id, dataset_id.to_i, h_pheno["raw"][dataset_id], h_sums, list_sex, nil)
        end
      end

#      h_all_sums = {}
#      if {:mean => h_sums[:mean].to_json}
      
      
  #    puts h_sums[:mean].to_json
      study.update(
        :pheno_mean_json => h_sums[:mean].to_json,
        :pheno_median_json => h_sums[:median].to_json,
        :pheno_sum_json => h_sums[:all].to_json
      )
      
    end

    ## sex_by_dgrp = {dgrp_line => [sexes with a value]} for each numeric phenotype of the study,
    ## derived from pheno_sum_json (call after upd_sums). Returns the number of phenotypes changed.
    def upd_sex_by_dgrp study
      h_pheno_sum = Basic.safe_parse_json(study.pheno_sum_json, {}) || {}
      h_sex = {}
      h_pheno_sum.each_key do |dgrp_line|
        sex_list = h_pheno_sum[dgrp_line]['sex'] || []
        h_pheno_sum[dgrp_line].keys.reject{|e| e == 'sex'}.each do |p|
          next if !h_pheno_sum[dgrp_line][p]
          h_sex[p] ||= {}
          h_sex[p][dgrp_line] ||= []
          h_pheno_sum[dgrp_line][p].each_index do |i|
            v = h_pheno_sum[dgrp_line][p][i]
            h_sex[p][dgrp_line].push sex_list[i] if v and v[0] and sex_list[i]
          end
        end
      end

      nber_changed = 0
      ## pheno_sum_json covers every dataset of the study; update_column avoids a useless Solr reindex
      Phenotype.where(:id => h_sex.keys.map(&:to_i), :study_id => study.id).each do |phenotype|
        json = h_sex[phenotype.id.to_s].to_json
        if phenotype.sex_by_dgrp != json
          phenotype.update_column(:sex_by_dgrp, json)
          nber_changed += 1
        end
      end
      return nber_changed
    end

    def upd_phenotype_name h_pheno, prev_name, new_name

      if h_pheno
        h_pheno.each_key do |dgrp_line|
          h_pheno[dgrp_line][new_name] = h_pheno[dgrp_line][prev_name].dup
          h_pheno[dgrp_line].delete(prev_name)
        end
      end
      return h_pheno
      
    end
    
    def upd_dataset_sums study_id, dataset_id, h_pheno, h_sums, sex_list, logger

      #  h_sums = {:mean => {}, :median => {}}
      #  h_pheno.each_key do |type|
      #  h_pheno[type]
      #    
      #  puts "toto"

      [:mean, :median, :all].each do |k|
        h_sums[k] ||= {}
      end
      
      h_all_phenos = {}
      h_pheno.each_key do |dgrp_line|
        h_pheno[dgrp_line].each_key do |p|
          h_all_phenos[p]=1
        end
      end       
      h_phenotypes = {}
      if study_id
        Phenotype.where(:study_id => study_id, :dataset_id => dataset_id, :name => h_all_phenos.keys).all.map{|p| h_phenotypes[p.name] = p}
      end
      #  puts h_phenotypes.to_json

     # logger.debug(h_pheno.to_json)
      
      h_pheno.each_key do |dgrp_line|
        phenos = h_pheno[dgrp_line].keys - ["sex"]
        sex =  h_pheno[dgrp_line]["sex"]
      #  logger.debug dgrp_line +  " -> " + sex.to_json
        h_sex_idx = {}
        sex.each_index do |i|
          h_sex_idx[sex[i]]||=[]
          h_sex_idx[sex[i]].push i
        end
        
        #  sex_list = h_sex_idx.keys.sort
        #  final_sex_list = existing_sex_list
        
        [:mean, :median, :all].each do |k|
          h_sums[k][dgrp_line] ||= {}
          sex_list.each do |s|
            h_sums[k][dgrp_line]["sex"]= sex_list
            #  h_sums[k][dgrp_line]["sex"].push(s) if ! h_sums[k][dgrp_line]["sex"].include? s            
          end
        end
       # first_dgrp_line = h_sums[:mean].first
       # final_sex_list = h_sums[:mean][first_dgrp_line]["sex"]
        
        phenos.each do |pheno|
          phenotype = (study_id) ? h_phenotypes[pheno] : pheno
          phenotype_id = (study_id and phenotype) ? phenotype.id : pheno
          # is_numeric = Basic.is_numeric_vector(h_pheno[dgrp_line][pheno])
          if phenotype
         #   logger.debug phenotype if logger
            #  puts phenotype.name
            if (study_id) ? phenotype.is_numeric : true
             # logger.debug "numeric" if logger
             # list_sums = (phenotype.is_summary == true) ? [:mean] : [:mean, :median, :variance, :std_dev, :std_err, :cv]
              tmp_v = {}
             # logger.debug sex_list if logger
             # logger.debug h_sex_idx.to_json if logger
              sex_list.each do |sex_item|
                #    puts sex_item
                list_val = (h_sex_idx[sex_item]) ? h_sex_idx[sex_item].map{|i| (h_pheno[dgrp_line][pheno]) ? h_pheno[dgrp_line][pheno][i] : nil} : []
                #                if phenotype.name == 'Cuticul_n_C28'
                #                  puts "#{dgrp_line} #{sex_item} => #{list_val.to_json}"
                #                end
                if logger
              #    logger.debug sex_item
              #    logger.debug list_val
                end
                [:mean, :median, :all].each do |k|
                  val = nil
                  if list_val.compact.size > 0
                    ## check if the list if only composed of ints
                    #  final_list = list_val.compact
                    if k == :mean
#                      logger.debug(list_val.to_json)
                      val = mean(list_val.compact)
                    elsif k == :median
                      val = median(list_val.compact)
                    elsif k == :all
                      l = list_val.compact
                      mean =  mean(l)
                      median = median(l)
                      variance = variance(l)
                      std_dev = std_dev(l)
                      std_err = std_err(l)
                      cvv = cv(l)
                      val = [mean, median, variance, std_dev, std_err, cvv]
                      
#                      if phenotype.id == 2635 and dgrp_line == 'DGRP_843'
#                        m = mean(l)
#                        #                        puts m
#                        sum = 0.0
#                        l.each {|v| sum += (v-m)**2; puts [v, m, sum].to_json }                        
#                        puts l.size.to_s + " -> " + l.to_json + " -> " + val.to_json
#                      end

                      
                      #                       val = variance(list_val.compact)
                      #                    elsif k == :std_dev
                      #                      val = std_dev(list_val.compact)
                      #                    elsif k == :std_err
                      #                      val = std_err(list_val.compact)
                      #                    elsif k== :cv
                      #                      val = cv(list_val.compact)
                    end
                  end
                  #   val = (list_val.compact.size > 0) ? (k==:mean) ? mean(list_val.compact) :  median(list_val.compact) : nil
                  #     puts [list_val.compact.size, val].to_json
                  tmp_v[k]||=[]
                  tmp_v[k].push(val)
                end
              end

              ## check if vector only contains int
              if tmp_v[:all]
                only_ints = [true, true]
                [0, 1].each do |i|
                  tmp_v[:all].compact.map{|e| e[i]}.each do |e|
                    if e.to_i.to_f != e.to_f
                      only_ints[i] = false
                      break
                    end
                  end
                end
                #                tmp_v[:all].compact.map{|e| e[1]}.each do |e|
                #                  if e.to_i.to_f != e.to_f
                #                    only_ints[1] = false
                #                    break
                #                  end
                #                end
                [0, 1].each do |i|
                  if only_ints[i] == true
                    tmp_v[:all] = tmp_v[:all].map{|e|
                      if e
                        e[i] = (e[i]) ? e[i].to_i : nil
                      end
                      e
                    }
                  end
                end
              end
              [:mean, :median, :all].each do |k|
                h_sums[k][dgrp_line][phenotype_id] = tmp_v[k]
              end
                
            else
            #  logger.debug "else" if logger
              sex_list.each_index do |sex_i|
                sex_item = sex_list[sex_i]
                list_val = (h_sex_idx[sex_item]) ? h_sex_idx[sex_item].map{|i| (h_pheno[dgrp_line][pheno]) ? h_pheno[dgrp_line][pheno][i] : nil} : []               
                [:mean, :median, :all].each do |k|
                   h_sums[k][dgrp_line][phenotype_id]||=[]
                  if list_val.compact.size == 1
                    h_sums[k][dgrp_line][phenotype_id][sex_i] = (k != :all) ? list_val.compact.first : [list_val.compact.first, list_val.compact.first, nil, nil, nil, nil]
                  elsif list_val.compact.size > 1
                    h_sums[k][dgrp_line][phenotype_id][sex_i] = (k != :all) ? "NC" : ["NC", "NC", nil, nil, nil, nil]
                  elsif list_val.compact.size == 0
                    h_sums[k][dgrp_line][phenotype_id][sex_i] = nil
                  end
                end
              end
#              sex_list.each do |sex_item|
#                [:all].each do |k|
#                   [mean, median, variance, std_dev, std_err, cvv]
#                  val = [h_pheno[dgrp_line][pheno][0], h_pheno[dgrp_line][pheno][0], 
#                         
#                end
           # end
            end
          else
            #            puts "ERROR: #{study_id} #{dataset_id} #{pheno} not found!"
          end
        end
      end
      
      #      study.update(
      #        :pheno_mean_json => h_sums[:mean].to_json,
      #        :pheno_median_json => h_sums[:median].to_json
      #      )
      
      return h_sums
      
    end

  end
end
