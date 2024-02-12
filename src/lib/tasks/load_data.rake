desc '####################### load data'
task load_data: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  ## read xlsx studies
  filepath = data_dir + "study_information.xlsx"
  xlsx = Roo::Spreadsheet.open(filepath.to_s)
  
  #  h_keywords = {}
  #  PhenotypeKeyword.all.map{||}
  #  h_categories = {}
  #  sheet = xlsx.sheets.first

   h_doi_by_study_id = {}
  
  xlsx.each_with_pagename do |name, sheet|
    if name == 'Sheet1'
      rows = sheet.to_matrix.to_a
      h_fields = {}
      #puts m.to_json
      rows.each_index do |i|
        row = rows[i]

        if i == 0
#          puts row.to_json  
          (0 .. row.size-1).to_a.map{|j| h_fields[row[j]] = j} 
        else
          #          puts row.to_json
          #Phenotype_Keywords","Mother_Class
          doi =  row[h_fields['DOI']].gsub(/^DOI: /, '').strip
          h_doi_by_study_id[row[h_fields['StudyID']]] = doi
          
          cat_names = row[h_fields['Mother_Class']]
          cat_names.split(",").map{|e| e.strip}.each do |cat_name|
            category = Category.where(:name => cat_name).first
            if !category
              category = Category.new(:name => cat_name)
#              category.save
            end
            
            study = Study.where(:doi => doi).first

            if ! study
                puts doi

              #              study = Study.new(:doi => doi, :status_id => 1)
#              study.save
            end
#            puts "Not found study with -#{doi}-"
#            category.studies << study if study and !category.studies.include? study
          end
          
        end

        i+=1
      end
      
      
    end
  end

  
  # get all phenotypes                                                                                                                                                                                                                  
  h_phenotypes = {}
  Phenotype.all.map{|p| h_phenotypes[[p.name, p.study_id]] = p}

  h_doi_by_study_id["SI007"] = "10.1128/AEM.03301-15"
  
#  puts  h_doi_by_study_id.to_json

  h_phenotypes2 = {}
  Phenotype.all.map{|p| h_phenotypes2[p.name] = p}

  h_phenotypes3 = {}
  
  h_studies_by_doi = {}
  Study.all.map{|s| h_studies_by_doi[s.doi] = s}
  
  #  data_file = data_dir + 'dictionnaryLines.json'
  #  h_data = JSON.parse(File.read(data_file))

  studies_ori_dir = data_dir + 'studies_ori'
  studies_dir = data_dir + 'studies'
  new_base_data_dir = data_dir + 'studies_base_data'
  
  Dir.new(studies_ori_dir).entries.select{|e| e.match(/^SI/)}.each do |d|

    doi = h_doi_by_study_id[d]
    study = Study.where(:doi => doi).first

    if study #and study.id == 12
    
    #    if d == 'SI101'
    #    data_file = studies_dir + d + 'Extract' + (d + ".json")
    #    if File.exist? data_file
    #      h_data = Basic.safe_parse_json(File.read(data_file), {})
    #      if h_data.keys.size == 0
    #        puts "Badly parsed: #{data_file}"
    #      end
    #    end

    data_file = studies_ori_dir + d + 'Extract' + (d + ".csv")
    base_data_dir =  studies_ori_dir + d + 'Base_data'
    
    puts data_file
    h_data = {}
    if File.exist? data_file
      rows = File.readlines(data_file)
      list_pheno = []
      error_lines = []
      rows.each_index do |i|
        l = rows[i]
        if i == 0
          t = l.chomp.gsub(/\"/, "").split(",")
            (3 .. t.size-1).map{|j| list_pheno[j-3] = t[j]}
        #          puts "List pheno: " + list_pheno.to_json
        else
          #                    puts l
          l = l.chomp.gsub(/\"/,"").gsub(/\],/, "]\t").gsub(/,\[/, "\t[").gsub(/^(\d+),(.+?)/,'\1' + "\t" + '\2')
          #                    puts l
          t = l.split("\t")
          #                     puts t.to_json
          #                      puts t.size
          #                      puts list_pheno.size
          #                      puts list_pheno.to_json

          list_pheno.each do |pheno|
            h_phenotypes3[[pheno, study.id]] = 1
          end
          
          if t.size == list_pheno.size + 3 and t[1].size < 10
            
            #                         puts "Valid line"
            h_data[t[1]]||={}
            sex = t[2].gsub(/[\[\]]/, '').gsub(/\'/, '').split(",").map{|e| e.strip}            
            h_data[t[1]]['sex'] = sex
            list_pheno.each_index do |j|              
              h_data[t[1]][list_pheno[j]] ||= {}
              vals = t[j+3].gsub(/[\[\]\']/, '').split(",").map{|e| e.strip}.map{|e|
#                puts e.to_json
                (["", "nan", "na", "n.a."].include? e.downcase) ? nil :
                  ((e.match(/^\-?\d+$/)) ? e.to_i : ((e.match(/^\-?\d*?\.?\d*?$/)) ? e.to_f : e))
              }
              
              if vals.compact.size != 0
                h_data[t[1]][list_pheno[j]] = vals
              end
              #      conditions.each_index do |m|
              #        k = conditions[m]
              #        if ! ["", "nan", "na", "n.a."].include? t[j+3].to_s.downcase.strip
              #          h_data[t[1]][list_pheno[j]][k] = vals[m] #t[j+3]
              #        end
              #      end
            end
          else
            error_lines.push i
          end
        end
      end
    end
    #    puts "ERRORS on lines: #{error_lines.to_json}"
  #  puts h_data.to_json
    
    #  if study and study.id == 12
      # write new file
      new_data_file = studies_dir + "#{study.id}.csv"
      new_base_data_study_dir = new_base_data_dir + study.id.to_s
      Dir.mkdir new_base_data_study_dir if !File.exist? new_base_data_study_dir
      FileUtils.cp_r(base_data_dir, new_base_data_study_dir) if File.exist? base_data_dir
      #      FileUtils.cp(data_file, new_data_file) if File.exist? data_file
      
      h_pheno_errors = {}
      
      h_data.each_key do |dgrp_line_name|
        dgrp_line = DgrpLine.where(:name => dgrp_line_name).first
        if !dgrp_line
          dgrp_line = DgrpLine.new(:name => dgrp_line_name, :user_id => 3)
          dgrp_line.save
        end
        
        #        puts h_doi_by_study_id.keys.to_json
        #        puts doi
        #        puts d
        #        puts h_doi_by_study_id[d]
        #        puts h_doi_by_study_id["SI001"]

        
        
#        if study
        #          puts "Study found"
        h_dls = {:dgrp_line_id => dgrp_line.id, :study_id => study.id, :user_id => 3}
        dls = DgrpLineStudy.where(h_dls).first
        if !dls
          dls = DgrpLineStudy.new(h_dls)
          dls.save
        end
 #       puts h_data.keys.to_json
        
        ActiveRecord::Base.transaction do
          h_data[dgrp_line_name].each_key do |pheno_name|
            #  phenotype = Phenotype.where(:name => pheno_name).first
            phenotype = h_phenotypes[[pheno_name, study.id]]
            #            there_is_data = false
            #            h_data[dgrp_line_name][pheno_name].each_key do |condition|
            #              there_is_data = true if !["", "nan", "na", "n.a."].include? h_data[dgrp_line_name][pheno_name][condition].to_s.downcase
            #            end
            #            there_is_data
            if phenotype and phenotype.id == 1416
#              puts "TEST!!!! #{h_data[dgrp_line_name][pheno_name].to_json}"
            end
            if phenotype and h_data[dgrp_line_name][pheno_name] and h_data[dgrp_line_name][pheno_name].size > 0
              dls.phenotypes << phenotype if !dls.phenotypes.include? phenotype
            end
            if pheno_name != 'sex' and !h_phenotypes2[pheno_name]
              h_pheno_errors[pheno_name]= 1
              h_phenotype = {
                :name => pheno_name,
                :description => '',
                :study_id => study.id
              }
              p = Phenotype.where(h_phenotype).first
              if !p
                p = Phenotype.new(h_phenotype)
                p.save
              end
              puts "add phenotype to dls"
              dls.phenotypes << p if !dls.phenotypes.include? p
              #              puts "Error: No phenotype for \"#{pheno_name}\" in #{d}"
            end
          end
        end
        
      end

      if h_pheno_errors.keys.size > 0
#        puts "#{h_pheno_errors.keys.size} phenotype not found (#{h_pheno_errors.keys.to_json})"
      end
      
      if h_data.keys.size > 0
        puts "Update study status"
       # study.update(:status_id => 4, :pheno_json => h_data.to_json)
        study.update(:pheno_json => h_data.to_json)
      end
      
    else

    #  puts "Study not found"
      
    end
   # end
  end

  h_phenotypes = {}
  Phenotype.all.map{|p| h_phenotypes[[p.name, p.study_id]] = p}
  
  phenodic_file = data_dir + 'phenodic.json'
  h_pheno = JSON.parse(File.read(phenodic_file))
  #  puts h_pheno.to_json                                                                                                                     
  puts  h_doi_by_study_id.to_json
  h_pheno.keys.each do |name|
    study = Study.where(:doi => h_doi_by_study_id[h_pheno[name][1]]).first
    if study
      #  phenotype = Phenotype.where(:name => name, :study_id => study.id).first                                                              
      phenotype = h_phenotypes[[name, study.id]]
      h_phenotype = {:name => name, :description => h_pheno[name][0], :study_id => study.id}
      if !phenotype
      #  phenotype = Phenotype.new(h_phenotype)
      #  phenotype.save
        puts "Issue"
      elsif study.id > 10
#        phenotype.update(h_phenotype)                                                                                                     
      end
    else
      puts "Study not found for \"#{h_pheno[name][1]}\""
    end
  end

  h_phenotypes.each_key do |k|
    if !h_phenotypes3[k]
      puts "Delete #{k.to_json}"
      h_phenotypes[k].dgrp_line_studies.delete_all
      h_phenotypes[k].destroy
    end
  end
  

  
end
