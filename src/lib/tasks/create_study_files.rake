desc '####################### create_study_files'
task create_study_files: :environment do

  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  #  phenotypes = Phenotype.all
  #  h_phenotypes = {}
  #  phenotypes.map{|p| h_phenotypes[p.name] = p}
  
  not_found = {}
  threshold = 0.3
  h_summary_types = {}
  SummaryType.all.map{|e| h_summary_types[e.name] = e}
  #  Study.all.select{|e| e.id == 46}.each do |study|
  Study.select(:id).map{|e| e.id}.select{|eid| eid != 22}.each do |study_id|
    study = Study.find(study_id)
    puts "Treating study " + study.id.to_s
    #    pheno_by_dgrp_line = data_dir + "studies" + "#{study.id}_global.csv"
    #    f1 = File.open(pheno_by_dgrp_line, 'w')
    #    pheno_by_sample =  data_dir + "studies" + "#{study.id}_by_sample_1.csv"
    #    f2 = File.open(pheno_by_sample, 'w')
    
    h_data = Basic.safe_parse_json(study.pheno_json_old, {})

    #    puts h_data.keys
    #  puts "KEYS" : h_data[h_data.keys.first].keys
    h_pheno = {}
    h_phenotypes = {}
    h_data.each_key do |dgrp_line|
      #     puts h_data[dgrp_line].keys
      h_data[dgrp_line].keys.select{|e| e != 'sex'}.each do |pheno|
        #   if p = Phenotype.where(:name => pheno).fisrt
        nber_vals =  h_data[dgrp_line][pheno].size
        
        h_pheno[pheno] ||= {:has_samples => 0}
        h_pheno[pheno][:has_samples] = 1 if h_data[dgrp_line]["sex"].size != h_data[dgrp_line]["sex"].uniq.size #h_pheno[pheno][:max_size] < nber_vals
        #   else
        #     puts "Study #{study.id} : #{pheno} not found!"
        #     
        #     not_found[study.id.to_s + ":" + pheno] = 1
        #   end
      end
      
    end

    list_pheno = h_pheno.keys.sort

    Phenotype.where(:name => list_pheno).all.each do |p|
      h_phenotypes[p.name]=p
    end
 
    list_pheno1 = list_pheno.select{|e| h_pheno[e][:has_samples] == 0 and e != 'sex'}
    list_pheno2 = list_pheno.select{|e| h_pheno[e][:has_samples] == 1 and e != 'sex'}

    h_data_final = {}
    
    if list_pheno1.size > 0
#      h_data_final = {:summary => h_data}
        
      list_pheno1.each do |e|
        is_numeric = true
        vals = h_data.keys.map{|k| h_data[k][e]}.flatten
        distinct_vals = vals.uniq
        is_continuous = (distinct_vals.size.to_f / vals.size > threshold) ? true : false
        h_data.each_key do |dgrp_line|
          if  h_data[dgrp_line][e].is_a? Array
            h_data[dgrp_line][e].each_index do |val_i|
              val = h_data[dgrp_line][e][val_i]
              if val.is_a? String and val.match(/-?\d+\.?\d*?e-?\d+/)
                puts val.class
                h_data[dgrp_line][e][val_i] = val.to_f 
                puts [val_i, val,  h_data[dgrp_line][e][val_i]].to_json
              #  exit
              end              
              is_numeric = false if !h_data[dgrp_line][e][val_i].is_a? Numeric
            end
          else
            if h_data[dgrp_line][e].is_a? Hash and h_data[dgrp_line][e].keys.size == 0
              h_data[dgrp_line][e] = nil
            end
            #            exit
          end
        end
        is_continuous = false if is_numeric == false
        sum_type = nil
        if h_phenotypes[e].description.match(/mean/i)
          sum_type = "mean"
        elsif h_phenotypes[e].description.match(/median/i)
          sum_type = "median"
        elsif h_phenotypes[e].description.match(/sd/i) or h_phenotypes[e].description.match(/standard deviation/i)
          sum_type = "sd"
        elsif h_phenotypes[e].description.match(/cv/i) or h_phenotypes[e].description.match(/coef[^ ]* of variation/i)
          sum_type = 'cv'
        end
        summary_type = h_summary_types[sum_type]
        h_phenotypes[e].update(:is_summary => true, :is_numeric => is_numeric, :is_continuous => is_continuous, :summary_type_id => (summary_type) ? summary_type.id : nil)
      end

      Dir.mkdir(data_dir + "studies" + study.id.to_s) if !File.exist? data_dir + "studies" + study.id.to_s      
      pheno_by_dgrp_line = data_dir + "studies" + "#{study.id}_summary.1.tsv"
      f1 = File.open(pheno_by_dgrp_line, 'w')
      
      ## print headers
      l1 = ["DGRP", "sex"] + list_pheno1 #.map{|e| h_phenotypes[e].name}
      f1.write(l1.join("\t") + "\n")

      ## write in final file                                                                                                                                                                                 
      h_data.each_key do |dgrp_line|
        h_data[dgrp_line]['sex'].each_index do |i|
          l1 = [dgrp_line, h_data[dgrp_line]['sex'][i]] + list_pheno1.map{|e| (h_data[dgrp_line][e] and h_data[dgrp_line][e][i]) ? h_data[dgrp_line][e][i] : ''}
          f1.write(l1.join("\t") + "\n")
        end
      end

      f1.close
      
      symlink = data_dir + "studies" + study.id.to_s + "#{study.id}_summary.tsv"
      File.symlink pheno_by_dgrp_line, symlink if !File.exist? symlink
      u = Upload.new({:study_id => study.id, :filename => "#{study.id}_summary.tsv", :version_id => 1})
      u.save
      h_data_final = {:summary => h_data}
    end
    
    
    if list_pheno2.size > 0
      
      list_pheno2.each do |e|
        is_numeric = true
        vals = h_data.keys.map{|k| h_data[k][e]}.flatten
        distinct_vals = vals.uniq
        is_continuous = ((distinct_vals.size.to_f / vals.size) > threshold) ? true : false
        h_data.each_key do |dgrp_line|
          if  h_data[dgrp_line][e].is_a? Array
            h_data[dgrp_line][e].each_index do |val_i|
              val = h_data[dgrp_line][e][val_i]
              if val.is_a? String and val.match(/-?\d+\.?\d*?e-?\d+/)
                puts val.class
                h_data[dgrp_line][e][val_i] = val.to_f
                puts [val_i, val,  h_data[dgrp_line][e][val_i]].to_json
                #  exit
              end
              is_numeric = false if !h_data[dgrp_line][e][val_i].is_a? Numeric
            end
          else
            if h_data[dgrp_line][e].is_a? Hash and h_data[dgrp_line][e].keys.size == 0
              h_data[dgrp_line][e] = nil
            end
          end
        end
        is_continuous = false if is_numeric == false
        puts e
        puts is_numeric
        puts is_continuous
        puts "#{OS.rss_bytes / 1_000_000} MB"

        h_phenotypes[e].update(:is_summary => false, :is_numeric => is_numeric, :is_continuous => is_continuous, :dataset_id => 1)
        puts "after"
      end

      Dir.mkdir(data_dir + "studies" + study.id.to_s) if !File.exist? data_dir + "studies" + study.id.to_s
      pheno_by_sample =  data_dir + "studies" + study.id.to_s + "#{study.id}_raw_1.1.tsv"
      f2 = File.open(pheno_by_sample, 'w')      
      
      #    l2 = ["DGRP line", "Sample index", "Sex"] + list_pheno2.map{|e| h_phenotypes[e].description}
      l2 = ["DGRP", "sex"] + list_pheno2 #.map{|e| h_phenotypes[e].name}
      f2.write(l2.join("\t") + "\n")

       ## write in final file

      h_data.each_key do |dgrp_line|
        h_data[dgrp_line]['sex'].each_index do |i|
          #   l2 = [dgrp_line, i+1, h_data[dgrp_line]['sex'][i]] + list_pheno2.map{|e| h_data[dgrp_line][e][i]}
          l2 = [dgrp_line, h_data[dgrp_line]['sex'][i]] + list_pheno2.map{|e| ( h_data[dgrp_line][e] and h_data[dgrp_line][e][i]) ? h_data[dgrp_line][e][i] : ''}
          f2.write(l2.join("\t") + "\n")
        end
      end
      
      f2.close


      symlink = data_dir + "studies" + study.id.to_s + "#{study.id}_raw_1.tsv"
      File.symlink pheno_by_sample, symlink if !File.exist? symlink

      u = Upload.new({:study_id => study.id, :filename => "#{study.id}_raw_1.tsv", :version_id => 1})
      u.save

      h_data_final = {:raw => { '1' => h_data}}

    end
    
    study.update(:pheno_json => h_data_final.to_json)
    
   #    exit
  end

  puts "#{not_found.keys.size} phenotypes not found"
  puts not_found.keys.map{|e| e.split(":").first.to_i}.sort.uniq.to_json
  puts not_found.keys.to_json
  
end

