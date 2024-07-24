desc '####################### compute_stats'
task compute_stats: :environment do
  puts 'Executing...'


  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  ## compute dgrp_lines stats
  
  dgrp_lines = DgrpLine.all
  
  h_studies = {}
  studies = Study.all
  studies.map{|s| h_studies[s.id] = s}

#  h_pheno_stats = {:nber_dgrp_lines => {}}
  
  h_phenotypes = {}
#  h_phenos_by_name = {}
  Phenotype.all.map{|p|
    h_phenotypes[p.id] = p
#    h_phenos_by_name[p.name] = p
#    h_pheno_stats[:nber_dgrp_lines][p.name] = 0
  }

  h_sex_types = {
    'M' => 'male',
    'F' => 'female',
    'NA' => 'na'
  }

  #  puts h_phenos_by_name.keys.size
#  h_not_found = {}

#  studies.each do |s|
#    h_pheno = Basic.safe_parse_json(s.pheno_json, {})
#    h_pheno.each_key do |dgrp_line|
#      phenos = h_pheno[dgrp_line].keys - ['sex']
#      phenos.each do |pheno|
#        if h_pheno[dgrp_line][pheno].compact.size > 0
#          if h_pheno_stats[:nber_dgrp_lines][pheno]
#            h_pheno_stats[:nber_dgrp_lines][pheno]+=1
#          else
#          #  puts "Pheno '#{pheno}' doesn't exist!"
#            h_not_found[pheno] =1
#          end
#        end
#      end
 #   end
#  end

#  puts h_not_found.keys.size
#  puts h_pheno_stats[:nber_dgrp_lines].keys.select{|k| h_pheno_stats[:nber_dgrp_lines][k] > 0}.size
#  exit
  
#  ActiveRecord::Base.transaction do
#    h_pheno_stats[:nber_dgrp_lines].each_key do |k|
#      if h_phenos_by_name[k]
#        puts "Update for #{k}"
#        h_phenos_by_name[k].update(:nber_dgrp_lines => h_pheno_stats[:nber_dgrp_lines][k])
#      end
#    end
#  end
#puts "Finished"
 # exit

  puts "Get DGRP lines"
  h_dgrp_studies = {}
  h_dgrp_line_studies = {}
  DgrpLineStudy.all.map{|e|
    h_dgrp_studies[e.dgrp_line_id] ||= [];
    h_dgrp_studies[e.dgrp_line_id].push e.study_id
    h_dgrp_line_studies[e.id] = e
  }
  
  h_phenotypes_by_dgrp_line = {}

  puts "Get phenotypes_dgrp_line_studies"
  
  Phenotype.joins(:dgrp_line_studies).select("dgrp_line_studies.id as dgrp_line_study_id, phenotypes.id as phenotype_id").all.map{|e|
    #puts e.to_json
    h_phenotypes_by_dgrp_line[h_dgrp_line_studies[e[:dgrp_line_study_id]].dgrp_line_id] ||= []
    h_phenotypes_by_dgrp_line[h_dgrp_line_studies[e[:dgrp_line_study_id]].dgrp_line_id].push e[:phenotype_id]
  }

  puts "Update dgrp line stats"
  
#  ActiveRecord::Base.transaction do
    dgrp_lines.each do |dgrp_line|
      h = {
        :nber_studies => (h_dgrp_studies[dgrp_line.id]) ? h_dgrp_studies[dgrp_line.id].size : 0,
        :nber_phenotypes => (h_phenotypes_by_dgrp_line[dgrp_line.id]) ? h_phenotypes_by_dgrp_line[dgrp_line.id].size : 0
      }
      dgrp_line.update(h)
    end
#  end

  h_nber_studies_by_cat = {}
  Category.joins("join categories_studies on (categories.id = categories_studies.category_id)").select("id as category_id, categories_studies.study_id as study_id").all.map{|e| h_nber_studies_by_cat[e[:category_id]] ||= 0;  h_nber_studies_by_cat[e[:category_id]] += 1}
  
  puts h_nber_studies_by_cat.to_json
  
  Category.all.map{|cat|
    cat.update({:nber_studies => h_nber_studies_by_cat[cat.id]})
  }
  
  h_stats_file = data_dir + 'stats.json'
  h_stats = {:sex => {}}
 # h_sex = {}
  ## compute sex distribution

  sel_studies = studies.select{|s| s.pheno_sum_json and s.pheno_sum_json != '' and s.pheno_sum_json != "{}"}
  
  h_study_datasets = {
    :all => sel_studies,
    :integrated => sel_studies.select{|s| s.status_id == 4}
  }

  h_study_datasets.each_key do |k|
    h_stats[:sex][k] = {}
    #  studies.select{|s| s.pheno_sum_json and s.pheno_sum_json != '' and s.pheno_sum_json != "{}"}.each do |study|
    h_study_datasets[k].each do |study|
      h_phenotypes = {}
      study.phenotypes.map{|e|
        h_phenotypes[e.id] = e
      }
      
      h_pheno = Basic.safe_parse_json(study.pheno_sum_json, {})
      #  puts h_pheno.to_json
      #  puts study.pheno_sum_json.to_json
      #  exit
      h_tmp = {}
 #     h_sex = {}
     
      if h_pheno
        h_pheno.each_key do |dgrp_line|
          h_tmp[dgrp_line] ||= []
          h_tmp[dgrp_line] |= h_pheno[dgrp_line]['sex']
  #        sex = h_pheno[dgrp_line]['sex']
  #        h_pheno[dgrp_line].keys.reject{|e| e == 'sex'}.each do |p|
  #          h_sex[p]||={:nber_sex_na => 0, :nber_sex_female => 0, :nber_sex_male => 0, :nber_dgrp_lines => 0}
#
#            h_pheno[dgrp_line][p].each_index do |i|
#              if h_pheno[dgrp_line][p][i]
#                h_sex[p]["nber_sex_#{h_sex_types[sex[i]]}"]+=1
#              end
#            end
        end
      end
      
      #  h_sex.each_key do |p|
      #    if h_phenotypes[p.to_i]
      #      h_phenotypes[p.to_i].update_attribute(:sex_by_dgrp, h_sex[p].to_json)
            #      else
            #        puts "Not found #{p} for study #{study.id}"
        #    end
        #    end
        
#        h_sex.each_key do |p|
#          if h_phenotypes[p.to_i]
#            h_phenotypes[p.to_i].update(h_sex[p])
#          end      
#        end
#      end
      
      #puts h_tmp
      h_tmp.each_key do |dgrp_line|
        h_tmp[dgrp_line].each do |s|
          h_stats[:sex][k][s] ||= 0
          h_stats[:sex][k][s] += 1
        end
      end

    end
  end
  
  #  h_stats[:h_sex] = h_sex

  phenotypes =  Phenotype.joins(:study).where(:obsolete => false).all
  nber_phenotypes_and_sex = 0
  phenotypes.each do |p|
    [p.nber_sex_male, p.nber_sex_female, p.nber_sex_na].each do |e|
      nber_phenotypes_and_sex+=1 if e and e > 0
    end
  end

  
  h_stats[:all_studies] = {
    :nber_all =>  Study.where(:status_id => [1, 2, 4]).count,
    :nber_integrated => Study.where(:status_id => 4).count,
    :nber_submitted => Study.where(:status_id => 1).count,
    :nber_validated => Study.where(:status_id => 2).count,
    :nber_phenotypes => Phenotype.where(:obsolete => false).count,
    :nber_phenotypes_and_sex => nber_phenotypes_and_sex,
    :nber_phenotypes_with_data => Phenotype.where("obsolete is false and (nber_sex_male > 0 or nber_sex_female > 0 or nber_sex_na > 0)").count,
    :nber_phenotypes_male => Phenotype.where("obsolete is false and nber_sex_male > 0").count,
    :nber_phenotypes_female => Phenotype.where("obsolete is false and nber_sex_female > 0").count,
    :nber_phenotypes_na => Phenotype.where("obsolete is false and nber_sex_na > 0").count
  }

  phenotypes =  Phenotype.joins(:study).where(:study => {:status_id => 4}, :obsolete => false).all
  nber_phenotypes_and_sex = 0
  phenotypes.each do |p|
    [p.nber_sex_male, p.nber_sex_female, p.nber_sex_na].each do |e|
      nber_phenotypes_and_sex+=1 if e and e > 0
    end
  end
  
  h_stats[:integrated_studies] = {
    :nber_phenotypes => Phenotype.joins(:study).where(:study => {:status_id => 4}, :obsolete => false).count,
    :nber_phenotypes_and_sex => nber_phenotypes_and_sex,
    :nber_phenotypes_with_data => Phenotype.joins(:study).where("studies.status_id = 4 and obsolete is false and (nber_sex_male > 0 or nber_sex_female > 0 or nber_sex_na > 0)").count,
    :nber_phenotypes_male => Phenotype.joins(:study).where("studies.status_id = 4 and obsolete is false and nber_sex_male > 0").count,
    :nber_phenotypes_female => Phenotype.joins(:study).where("studies.status_id = 4 and obsolete is false and nber_sex_female > 0").count,
    :nber_phenotypes_na => Phenotype.joins(:study).where("studies.status_id = 4 and obsolete is false and nber_sex_na > 0").count
  }
  
  h_stats[:dgrp_lines] = {:nber =>  DgrpLine.count}
  h_stats[:categories] = {:nber => Category.count}
  h_stats[:phenotypes] = {:nber_validated => Phenotype.where(:obsolete => false).count}
  h_stats[:by_category] = {}
  Category.all.each do |c|
#    all_studies = c.studies
    h_stats[:by_category][c.id] = {
      :all => Study.joins("join categories_studies on (studies.id = study_id) ").where("categories_studies.category_id = #{c.id}").count,
      :integrated => Study.joins("join categories_studies on (studies.id = study_id)").where("categories_studies.category_id = #{c.id} and status_id = 4").count
    }
  end
  
  puts h_stats[:sex].to_json

  File.open(h_stats_file, 'w') do |f|
    f.write h_stats.to_json
  end

end

