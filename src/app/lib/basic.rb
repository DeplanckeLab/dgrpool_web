module Basic

  class << self

    def compute_correlation t_header, content #, pheno_name

      h_res = {}

      md5 = Digest::SHA256.hexdigest content
      data_dir = Pathname.new(APP_CONFIG[:data_dir])
      tmp_file = data_dir + "tmp" + "#{md5}.tmp"
      output_dir =  data_dir + "tmp" + md5
      
      export_mean_file = data_dir + 'export_mean.tsv'
      t_header[0] = 'DGRP'
      if !File.exist? tmp_file
        Dir.mkdir(output_dir) if !File.exist? output_dir
        File.open(tmp_file, 'w') do |f|
          f.write(t_header.join("\t") + "\n" )
          f.write(content)
        end
      end

      plink_file = data_dir + 'dgrp2'
      cov_file = data_dir + "dgrp.cov.tsv"
      annot_file = data_dir + "dgrp.fb557.annot.txt.gz"
     
      #      cmd = "Rscript running_GWAS_user.R #{tmp_file} #{plink_file} #{cov_file} #{annot_file} #{output_dir} 2 0.2 0.05 1> #{output_dir + "gwas_output.json"} 2> #{output_dir + "gwas_output.err"}"
      
      #      if !File.exist? output_dir
      Dir.mkdir output_dir if !File.exist? output_dir
      cmd = "java -jar /srv/dgrpool/lib/DGRPool-1.0.jar AllCorrelations --pheno #{tmp_file} --phenodb #{export_mean_file} -o #{output_dir} 1> #{output_dir + 'output.json'} 2> #{output_dir + 'output.err'}"
      res = `#{cmd}`
      #      end
      #      File.delete tmp_file if File.exist? tmp_file

      output_json = output_dir + 'output.json'
    #  puts "OUTPUT_JSON: " + output_json.to_s
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
        h_sums = upd_dataset_sums(study.id, nil, h_pheno["summary"], h_sums, list_sex)
      end
      if h_pheno["raw"]
        h_pheno["raw"].each_key do |dataset_id|
          h_sums = upd_dataset_sums(study.id, dataset_id.to_i, h_pheno["raw"][dataset_id], h_sums, list_sex)
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

    def upd_phenotype_name h_pheno, prev_name, new_name

      if h_pheno
        h_pheno.each_key do |dgrp_line|
          h_pheno[dgrp_line][new_name] = h_pheno[dgrp_line][prev_name].dup
          h_pheno[dgrp_line].delete(prev_name)
        end
      end
      return h_pheno
      
    end
    
    def upd_dataset_sums study_id, dataset_id, h_pheno, h_sums, sex_list

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
      
      h_pheno.each_key do |dgrp_line|
        phenos = h_pheno[dgrp_line].keys - ["sex"]
        sex =  h_pheno[dgrp_line]["sex"]
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
            #  puts phenotype.name
            if (study_id) ? phenotype.is_numeric : true
              #  puts "numeric"
             # list_sums = (phenotype.is_summary == true) ? [:mean] : [:mean, :median, :variance, :std_dev, :std_err, :cv]
              tmp_v = {}
              sex_list.each do |sex_item|
                #    puts sex_item
                list_val = (h_sex_idx[sex_item]) ? h_sex_idx[sex_item].map{|i| (h_pheno[dgrp_line][pheno]) ? h_pheno[dgrp_line][pheno][i] : nil} : []
                #                if phenotype.name == 'Cuticul_n_C28'
                #                  puts "#{dgrp_line} #{sex_item} => #{list_val.to_json}"
                #                end
                
                [:mean, :median, :all].each do |k|
                  val = nil
                  if list_val.compact.size > 0
                    ## check if the list if only composed of ints
                    #  final_list = list_val.compact
                    if k == :mean
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
