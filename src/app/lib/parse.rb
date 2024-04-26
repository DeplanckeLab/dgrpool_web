module Parse

  class << self

    def parse_user_tsv data, logger, integrate
      h_data = {}
      h_sex = {}
      h_discarded_phenotypes = {} #{"sex" => 1}
      h_duplicated_dgrp_lines = {}
      errors = []
      warnings = []
      lines =  data.split(/[\r\n]+/)
      #  logger.debug(lines)
      header = lines.shift
      #  logger.debug(header)                                                                                                                                                                                
      t_header = header.split("\t")
      if t_header.uniq.size != t_header.size
        errors.push "Header contains duplicated columns"
      elsif t_header.size < 2 #or t_header[0] != 'dgrp_line' or t_header[1] != 'sex'      
        errors.push "Header doesn't contain enough columns (minimum 2) current_number=#{t_header.size}, header=#{t_header.to_json}"
      elsif t_header[0] != 'DGRP' #or t_header[1] != 'sex'
        errors.push "Header is invalid, first column should be 'DGRP'"
      end
      not_accepted_names = (1 .. t_header.size-1).to_a.select{|i| !t_header[i].match(/^\s*[\w\d_]{1..20}\s*$/)}.map{|i| t_header[i]}
      if not_accepted_names.size > 0 and integrate == true
        errors.push "Header names are not following the naming rules (max 20 characters [alphanumerical and '_'): #{not_accepted_names.join(", ")}"
      end
      add_sex = false
      if t_header[1] != 'sex'
        add_sex = true
        t_header.insert(1, "sex")
      end
      not_enough_cols = []
      not_same_col_nber = []
      invalid_sex = []
      invalid_dgrp = []
      dgrp_lines = []
      dgrp_lines_by_sex = {} 
      (2 .. t_header.size-1).to_a.map{|i| t_header[i] = t_header[i].gsub(/[^a-zA-Z0-9]+/, '_')}
      phenotypes = (1 .. t_header.size-1).to_a.map{|i| t_header[i]}
      new_lines = []
      lines.each_index do |j|
        l = lines[j]
        t = l.split("\t", -1).map{|e| e.strip}
        t.insert(1, "NA") if add_sex == true
        h_sex[t[1]] = 1
        nber = t[0].gsub(/[^\d]|-/, '')
        if t.size < 3
          not_enough_cols.push j+2
        elsif !['M', 'F', 'NA'].include? t[1]
          invalid_sex.push j+2 #errors.push "sex column should contains only "                                                                                           
        elsif nber != '' and 3-nber.size >= 0
          dgrp_line_name = "DGRP_" + ("0" * (3-nber.size)) + nber
          t[0] = dgrp_line_name
          if h_data[dgrp_line_name] and h_data[dgrp_line_name]['sex'].include? t[1]
            h_duplicated_dgrp_lines[dgrp_line_name + "/" + t[1]] = 1
          else
            h_data[dgrp_line_name] = {'sex' => []}
          end
        
          
          new_lines.push t
          
          (2 .. t.size-1).to_a.each do |i|
            numerical = true
            if ['', 'na', 'NA'].include? t[i]
              val = nil
            elsif t[i].match(/^\-?\d+$/)
              val = t[i].to_i
            elsif t[i].match(/^\-?\d*?\.?\d*?$/) or t[i].match(/^-?\d+\.?\d*?[eE][\-+]?\d+$/)
              val = t[i].to_f
            else
              val = t[i]
              numerical = false
            end
            # logger.debug("NUMERICAL: " + numerical.to_s)
            if numerical == false
              #  logger.debug("NUMERICAL FALSE")
              h_discarded_phenotypes[t_header[i]] = 1 
            end
            h_data[dgrp_line_name]['sex'].push t[1] if i == 2
            h_data[dgrp_line_name][t_header[i]]||=[]
            h_data[dgrp_line_name][t_header[i]].push val
          end
          
          dgrp_lines.push dgrp_line_name
          dgrp_lines_by_sex[t[1]]||=[]
          dgrp_lines_by_sex[t[1]].push dgrp_line_name
          
          if t_header.size != t.size
            not_same_col_nber.push t[0] + " (#{t.size})"
          end

        else
          invalid_dgrp.push j+2
        end
        if t_header.size != t.size
          not_same_col_nber.push t[0] + " (#{t.size})"
        end
      end
      if add_sex == true
        warnings.push("Column 'sex' not found in second position, thus it has been added setting all values to NA.")
      end
      if h_duplicated_dgrp_lines.keys.size > 0
        errors.push("Some DGRP lines are not unique by sex (#{h_duplicated_dgrp_lines.keys.join(", ")}).<br/><b>Please summarize your dataset by DGRP line and sex prior upload.</b>")
      end
      if invalid_sex.size > 0
        errors.push "Lines with invalid sex were ignored. Sex column should contain only one of ['M', 'F', 'NA'] values which is not the case on line(s) #{invalid_sex.join(", ")}"
      end
      if invalid_dgrp.size > 0
        errors.push "Lines with invalid DGRP line were ignored. DGRP line column contains a wrong value on lines #{invalid_dgrp.join(", ")}"
      end
      if not_enough_cols.size > 0
        errors.push "Lines with less than 3 columns were ignored: lines #{not_enough_cols.join(", ")}"
      end
      
      if not_same_col_nber.size > 0
        errors.push "Not the same number of columns for DGRP #{not_same_col_nber.join(",")} compared to header (#{t_header.size} column(s))."
      end

      h_data = {
        :errors => errors,
        :warnings => warnings,
        :discarded_phenotypes => h_discarded_phenotypes.keys,
        :phenotypes => phenotypes - h_discarded_phenotypes.keys - ['sex'],
        :dgrp_lines => dgrp_lines,
        :dgrp_lines_by_sex => dgrp_lines_by_sex,
        :header => t_header,
        :matrix => new_lines, #.map{|e| e.split("\t")},
        :h_pheno => h_data,
        :sex_list => h_sex.keys
      }
      
      return h_data
      
    end

    
    def parse_tsv data, logger
      h_data = {}
      errors = []
      lines =  data.split(/[\r\n]+/)
    #  logger.debug(lines)
      header = lines.shift
    #  logger.debug(header)
      t_header = header.split("\t")
      #      h_phenos = {}
      if t_header.uniq.size != t_header.size
        errors.push "Header contains duplicated columns"
      elsif t_header.size < 3 #or t_header[0] != 'dgrp_line' or t_header[1] != 'sex'
        errors.push "Header doesn't contain enough columns (minimum 3) current_number=#{t_header.size}, header=#{t_header.to_json}"
      elsif t_header[0] != 'DGRP' or t_header[1] != 'sex'
        errors.push "Header is invalid, 2 first columns should be 'DGRP' and 'sex'"
      end

      if errors.size == 0
        h_header = {}
        bad_nber_cols = []
        phenotypes = (2 .. t_header.size).map{|i| h_header[t_header[i]] = i}
        bad_len_phenotypes = []
        bad_char_phenotypes = []
        h_header.keys.compact.each do |phenotype|
          bad_len_phenotypes.push phenotype if phenotype.size > 20 
          bad_char_phenotypes.push phenotype if !phenotype.match(/^[a-zA-Z_0-9]+$/)
        end
        errors.push "Phenotype names longer than 20 characters #{bad_len_phenotypes.to_json}" if bad_len_phenotypes.size > 0
        errors.push "Phenotype names with unautorized characters (only a-z, A-Z, 0-9 and '_'): #{bad_char_phenotypes.to_json}" if bad_char_phenotypes.size > 0
        
        lines.each_index do |j|
          l = lines[j]
          t = l.split("\t", -1).map{|e| e.strip} ## -1 to keep trailing empty fields
          if t.size == 1 and t[0] == ''
            ## ignore blank line
          elsif t.size == t_header.size
            nber = t[0].gsub(/[^\d]|-/, '')
            dgrp_line_name = "DGRP_" + ("0" * (3-nber.size)) + nber
            h_data[dgrp_line_name] ||= {'sex' => []}            
            (2 .. t.size-1).to_a.each do |i|
              if ['', 'na', 'NA'].include? t[i]
                val = nil
              elsif t[i].match(/^\-?\d+$/)
                val = t[i].to_i
              elsif t[i].match(/^\-?\d*?\.?\d*?$/) or t[i].match(/^-?\d+\.?\d*?[eE][\-+]?\d+$/)
                val = t[i].to_f
              else
                val = t[i]
              end
              h_data[dgrp_line_name]['sex'].push t[1] if i == 2
              h_data[dgrp_line_name][t_header[i]]||=[]
              h_data[dgrp_line_name][t_header[i]].push val
            end
          else
            bad_nber_cols.push(j)
            #   logger.debug(l.to_json)
          end
        end
        if bad_nber_cols.size > 0
          errors.push "Bad number of cols for lines # #{bad_nber_cols.join(",")}"
        end
      end
      
      return {:h_data => h_data, :errors => errors, :stats => {:nber_lines => lines.size}}
    end
    
    def parse_csv study_id
      studies_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'studies'
      data_file = studies_dir + "#{study_id}.csv" #) d + 'Extract' + (d + ".csv")
    #  puts data_file
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
          else
            l = l.chomp.gsub(/\"/,"").gsub(/\],/, "]\t").gsub(/,\[/, "\t[").gsub(/^(\d+),(.+?)/,'\1' + "\t" + '\2')
            t = l.split("\t")
            if t.size == list_pheno.size + 3 and t[1].size < 10
              h_data[t[1]]||={}
              sex = t[2].gsub(/[\[\]]/, '').split(",")
              h_data[t[1]]['sex'] = sex
              list_pheno.each_index do |j|
                h_data[t[1]][list_pheno[j]] ||= {}
                vals = t[j+3].gsub(/[\[\]\']/, '').split(",").map{|e| (["", "nan", "na", "n.a."].include? e.downcase.strip) ? nil : ((e.match(/^\-?\d+$/)) ? e.to_i : ((e.match(/^\-?\d*?\.?\d*?$/) or e.match(/^-?\d+\.?\d*?[Ee][\-+]?\d+/)) ? e.to_f : e))  }
                
                if vals.compact.size != 0
                  h_data[t[1]][list_pheno[j]] = vals
                end
              end  
            else
              error_lines.push i
            end
          end
        end
        puts "ERRORS on lines: #{error_lines.to_json}"

        doi = h_doi_by_study_id[d]
        study = Study.where(:doi => doi).first
        h_pheno_errors = {}
        
        h_data.each_key do |dgrp_line_name|
          dgrp_line = DgrpLine.where(:name => dgrp_line_name).first
          if !dgrp_line
            dgrp_line = DgrpLine.new(:name => dgrp_line_name, :user_id => 3)
            dgrp_line.save
          end
          
          if study
            
            h_dls = {:dgrp_line_id => dgrp_line.id, :study_id => study.id, :user_id => 3}
            dls = DgrpLineStudy.where(h_dls).first
            if !dls
              dls = DgrpLineStudy.new(h_dls)
              dls.save
            end
            
            
            ActiveRecord::Base.transaction do
              h_data[dgrp_line_name].each_key do |pheno_name|

                phenotype = h_phenotypes[[pheno_name, study.id]]
                if phenotype and h_data[dgrp_line_name][pheno_name].keys.size > 0
                  dls.phenotypes << phenotype if !dls.phenotypes.include? phenotype
                else
                  h_pheno_errors[pheno_name]= 1
                end
              end
            end
            
          end
        end
        
        if h_pheno_errors.keys.size > 0
          puts "#{h_pheno_errors.keys.size} phenotype not found (#{h_pheno_errors.keys.to_json})"
        end
        
        if h_data.keys.size > 0
          puts "Update study status"
          study.update(:status_id => 4, :pheno_json => h_data.to_json)
        end
        
        
      end

    end
  end
end
