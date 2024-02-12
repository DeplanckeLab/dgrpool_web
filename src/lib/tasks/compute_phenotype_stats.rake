desc '####################### compute_phenotype_stats'
task compute_phenotype_stats: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  ## compute dgrp_lines stats                                                                                                                                            

  dgrp_lines = DgrpLine.all

#  h_studies = {}
#  studies = Study.all
#  studies.map{|s| h_studies[s.id] = s}

  h_sex = {
    "F" => 'female',
    "M" => 'male',
    "NA" => 'na'
  }
  
#  puts h_phenos_by_name.keys.size
  h_not_found = {}

  Study.all.each do |s|
    h_phenotypes = {}
    s.phenotypes.map{|p|
      h_phenotypes[p.id] = p
    }
    
    puts "Study #{s.id}"
  #  puts s.pheno_sum_json
    h_pheno = Basic.safe_parse_json(s.pheno_sum_json, {})
    h_pheno_stats = {:nber_dgrp_lines => {}, :nber_sex_female => {}, :nber_sex_male => {}, :nber_sex_na => {}}
    s.phenotypes.each do |p|
      h_pheno_stats.each_key do |k|
        h_pheno_stats[k][p.id.to_s] = 0
      end
    end
    
    h_pheno.each_key do |dgrp_line|
      phenos = h_pheno[dgrp_line].keys - ['sex']
#      puts phenos
      sex = h_pheno[dgrp_line]['sex']

      phenos.each do |pheno|
        if h_pheno[dgrp_line][pheno].compact.size > 0
          if h_pheno_stats[:nber_dgrp_lines][pheno]
            h_pheno_stats[:nber_dgrp_lines][pheno]+=1
          end
        else
          h_not_found[pheno] =1
        end
#        puts sex.size
        sex.each_index do |sample_i|
          s = h_sex[sex[sample_i]]
          k = ("nber_sex_" + s).to_sym
          if ! h_pheno_stats[k]
#            puts k
#            exit
          end
          if h_pheno_stats[k][pheno] and h_pheno[dgrp_line][pheno][sample_i]
            h_pheno_stats[k][pheno]+=1
#            puts "ADD TO #{k}" 
          end
          
        end

        
      end

    end
    h_pheno_stats[:nber_dgrp_lines].each_key do |pheno|
      h_upd = {}
      h_pheno_stats.each_key do |k|
        h_upd[k] = h_pheno_stats[k][pheno]
      end
#      puts h_upd.to_json if pheno == '2257'
      h_phenotypes[pheno.to_i].update_columns(h_upd)                                                                                                                       
#      puts Phenotype.find(2257).to_json if pheno == '2257' 
    end
    
  end

  #  puts h_not_found.keys.size                                                                                                                                            
  #  puts h_pheno_stats[:nber_dgrp_lines].keys.select{|k| h_pheno_stats[:nber_dgrp_lines][k] > 0}.size                                                                     
  #  exit                                                                                                                                                                  
  
  #  ActiveRecord::Base.transaction do                                                                                                                                     
  #  h_pheno_stats[:nber_dgrp_lines].each_key do |k|
  #    if h_phenos_by_name[k]
  #      #        puts "Update for #{k}"
  #      h_upd = {}
  #      h_pheno_stats.each_key do |k2|
  #        h_upd[k2] = h_pheno_stats[k2][k]
  #      end
  #      #puts h_upd.to_json
  #      h_phenos_by_name[k].update(h_upd)
  #    end
  #  end
  #  end
  
  puts "Finished"
  
end
