desc '####################### create export'
task create_export: :environment do
  puts 'Executing...'
  
  time = Time.now
  
  h_json = "{" + Study.all.map{|e| "\"#{e.id}\":#{(e.pheno_mean_json) ? e.pheno_mean_json : 'null'}"}.join(",") + "}"

  File.open("/data/dgrpool/export_mean.json", "w") do |fw|
    fw.write(h_json)
  end

  h = Basic.safe_parse_json(h_json, {})

#  puts h.to_json
  
  list_dgrp_lines = DgrpLine.all.sort{|a, b| a.name <=> b.name}
  h_dgrp_lines = {}
  list_dgrp_lines.each_index do |i|
    h_dgrp_lines[list_dgrp_lines[i].name] = i
  end
  
  list_phenotypes = Phenotype.where(:obsolete => false, :is_numeric => true).all.sort
  h_phenotypes = {}
  
  list_phenotypes.each_index do |i|
    p = list_phenotypes[i]
    h_phenotypes[p.id.to_s] = i
    #    list_sex = [(p.nber_sex_male and p.nber_sex_male > 0) ? 'M' : nil, (p.nber_sex_female and p.nber_sex_female > 0) ? 'F' : nil, (p.nber_sex_na and p.nber_sex_na > 0) ? 'NA' : nil].compact
    #    h_sex_by_phenotype[list_phenotypes[i].id.to_s] = list_sex
  end
  
  #initialize matrix
  matrix = []
  list_dgrp_lines.each_index do |i|
    # (0 .. 2).to_a.each do |j| # each sex
    matrix.push [] #list_phenotypes.map{|p| h_sex_by_phenotype[p.id.to_s].map{|k| nil}}.flatten
    #  end
  end
  
  list_sex = ['M', 'F', 'NA']
  h_sex = {'M' => 0, 'F' => 1, 'NA' => 2}


  ## define sex by phenotype
  h_sex_by_phenotype = {}
  h_tmp = {}
  h.each_key do |study_id|
    if h[study_id]
      h[study_id].each_key do |dgrp_line|
#        puts dgrp_line
        h[study_id][dgrp_line].keys.select{|pid| h_phenotypes[pid]}.each do |phenotype_id|
#          puts "titi"
          if ! h_sex_by_phenotype[phenotype_id]
            h_tmp[phenotype_id] ||= {}
            h[study_id][dgrp_line]['sex'].each_index do |i|
              if h[study_id][dgrp_line][phenotype_id][i]
                h_tmp[phenotype_id][h[study_id][dgrp_line]['sex'][i]] = 1 #.push h[study_id][dgrp_line]['sex'][i]
              end
            end
#            h_sex_by_phenotype[phenotype_id] = tmp_sex #h[study_id][dgrp_line]['sex']
#            puts "#{h[study_id][dgrp_line]['sex'].to_json}"
          end
        end
      end
    end
  end

  h_tmp.each_key do |phenotype_id|
    h_sex_by_phenotype[phenotype_id] = h_tmp[phenotype_id].keys
  end
  

  ##filter out phenotypes without data
  h_phenotypes = {}
#  puts list_phenotypes.map{|p| p.id}.to_json
  filtered_list_phenotypes = list_phenotypes.select{|p| h_sex_by_phenotype[p.id.to_s]}
  puts "=>Number phenotypes: #{filtered_list_phenotypes.size}"
  test_phenotypes = Phenotype.where("obsolete = false and is_numeric = true and (nber_sex_na > 0 or nber_sex_male > 0 or nber_sex_female > 0)").all
  puts (test_phenotypes - filtered_list_phenotypes).size
  puts (filtered_list_phenotypes- test_phenotypes).size
  puts (filtered_list_phenotypes- test_phenotypes).map{|e| "#{e.id} - #{e.name}"}.to_json
  filtered_list_phenotypes.each_index do |i|
    p = filtered_list_phenotypes[i]
    h_phenotypes[p.id.to_s] = i
  end
  
  
  h.each_key do |study_id|
    if h[study_id]
      h[study_id].each_key do |dgrp_line|
        h[study_id][dgrp_line].keys.select{|pid| h_phenotypes[pid]}.each do |phenotype_id|
         # if h_sex_by_phenotype[phenotype_id]
            h[study_id][dgrp_line][phenotype_id].each_index do |i|
              s = h[study_id][dgrp_line]['sex'][i]
              if  h_sex_by_phenotype[phenotype_id].include? s
                s_i = h_sex_by_phenotype[phenotype_id].index(s)
                #             puts "DGRP #{dgrp_line} #{s}: #{h[study_id][dgrp_line][phenotype_id][i]} #{h_phenotypes[phenotype_id] + s_i}" if phenotype_id == '1362'
                #            puts s, s_i
                #            puts dgrp_line, h_dgrp_lines[dgrp_line]
                #            puts h_phenotypes[phenotype_id]
                matrix[h_dgrp_lines[dgrp_line]][h_phenotypes[phenotype_id]] ||=[]
                matrix[h_dgrp_lines[dgrp_line]][h_phenotypes[phenotype_id]][s_i] = h[study_id][dgrp_line][phenotype_id][i]
              end
            end
         # end
        end
      end
    end
  end
  
#  matrix.reject!{|e| e.compact.size == 0}

  puts filtered_list_phenotypes.map{|e| e.id.to_s}.join(",")
#  puts filtered_list_phenotypes.map{|e| h_sex_by_phenotype[e.id.to_s].map{|sex| "#{e.id}_#{sex}"}}.join(",")

  File.open("/data/dgrpool/export_phenotypes.tsv", "w") do |fw|
    fw.write(["phenotype_identifier", "phenotype_id", "sex", "study_id", "phenotype_name", "phenotype_description"].join("\t") + "\n")
    filtered_list_phenotypes.each do |e|
      h_sex_by_phenotype[e.id.to_s].each do |sex|
        fw.write(["#{e.id}_#{sex}", e.id.to_s, sex, e.study_id, e.name, e.description.gsub(/\n+$/, '')].join("\t") + "\n")
      end
    end
  end

  
  File.open("/data/dgrpool/export_mean.tsv", "w") do |fw|
    fw.write((["DGRP"] + filtered_list_phenotypes.map{|e| h_sex_by_phenotype[e.id.to_s].map{|sex| "#{e.id}_#{sex}"}}.flatten).join("\t") + "\n")
    list_dgrp_lines.each_index do |i|
      #      list_sex.each_index do |j|
      if matrix[i]
        t = [list_dgrp_lines[i].name] +
            (0 .. filtered_list_phenotypes.size-1).to_a.map{|p_i|
          pid = filtered_list_phenotypes[p_i].id.to_s
          (0 .. h_sex_by_phenotype[pid].size-1).to_a.map{|s_i|
            #"#{p_i}:#{s_i}:" +
            ((matrix[i][p_i]) ? matrix[i][p_i][s_i].to_s : "")
          }
        }.flatten
#        puts i, t.size
#        puts t.to_json
        fw.write(t.join("\t") + "\n")
      #      end
      else
        puts "matrix null for #{i}"
      end
    end
  end
  
  puts "Elapsed time:" + (Time.now-time).to_s
 
end

