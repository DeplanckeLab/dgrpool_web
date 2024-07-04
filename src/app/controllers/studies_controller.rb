class StudiesController < ApplicationController
  before_action :set_study, only: %i[ show edit update destroy upd_cats upd_disabled_phenotypes upd_disabled_dgrp_line_studies get_file upload_form parse_dataset del_dataset]

  def upd_disabled_dgrp_line_studies

      if curator? and params[:disabled_dgrp_line_studies]
      disabled_dgrp_line_study_ids =  params[:disabled_dgrp_line_studies].split(",").map{|e| e.to_i}
      h_dp = {}
      Phenotype.where(:id => disabled_dgrp_line_study_ids).all.map{|p| h_dp[p.id] = p}

      @study.dgrp_line_studies.each do |p|
        if p.obsolete == false and  disabled_dgrp_line_study_ids.include? p.id
          p.update(:obsolete => true)
        elsif p.obsolete == true and ! disabled_dgrp_line_study_ids.include? p.id
          p.update(:obsolete => false)
        end
      end
    end
    render :partial => "disabled_dgrp_line_studies", :locals => {:study => @study}

  end
  
  def upd_disabled_phenotypes

    if curator? and params[:disabled_phenotypes]
      disabled_phenotype_ids =  params[:disabled_phenotypes].split(",").map{|e| e.to_i}
      h_dp = {}
      Phenotype.where(:id => disabled_phenotype_ids).all.map{|p| h_dp[p.id] = p}

#      cat_ids = params[:categories].split(",").map{|e| e.to_i}
      #  h_existing_cats = {}
      #logger.debug("disabled_phenotype_ids:" + disabled_phenotype_ids.to_json)
      @study.phenotypes.each do |p|
        if p.obsolete == false and  disabled_phenotype_ids.include? p.id
          p.update(:obsolete => true)
        elsif p.obsolete == true and ! disabled_phenotype_ids.include? p.id
          p.update(:obsolete => false)
        end
      end
      #   cats =  @study.categories                                                                                                             
      #      cat_ids.each do |cat_id|
      #        @study.categories << h_cats[cat_id] if !@study.categories.include? h_cats[cat_id]
      #      end
    end
    render :partial => "disabled_phenotypes", :locals => {:study => @study}
  end

  
  def upd_cats
    if curator? and params[:categories]
      h_cats = {}
      Category.all.map{|c| h_cats[c.id] = c}

      cat_ids = params[:categories].split(",").map{|e| e.to_i}
      #  h_existing_cats = {}
      @study.categories.each do |cat|
        if ! cat_ids.include? cat.id
          @study.categories.delete(h_cats[cat.id])
        end
      end
      #   cats =  @study.categories
      cat_ids.each do |cat_id|
        @study.categories << h_cats[cat_id] if !@study.categories.include? h_cats[cat_id]
      end
    end
    render :partial => "categories", :locals => {:study => @study}
  end

  def del_dataset
    @log = []
    if curator?

#      h_all_dgrp_lines = {}
#      DgrpLine.all.map{|d| h_all_dgrp_lines[d.id] = d}
      
        data_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'studies'
        @h_pheno = Basic.safe_parse_json(@study.pheno_json, {})
        if params[:dataset] == 'summary'
          @h_pheno.delete('summary')
        elsif  m = params[:dataset].match(/raw_(\d+)/)
          @raw_id = m[1]
          @h_pheno['raw'].delete(@raw_id)
        end

        # get all dgrp_lines
        all_phenotypes = Phenotype.where(:study_id => @study.id).all
        #phenotypes_to_keep =  Phenotype.where(:study_id => @study.id, :is_summary => (params[:dataset] == 'summary') ? false : true).all.reject{|e| @raw_id and @raw_id.to_i == e.dataset_id} #, :is_summary => ((params[:dataset] == 'summary') ? true : false), :dataset_id => @raw_id).all
        phenotypes_to_del =  Phenotype.where(:study_id => @study.id, :is_summary => (params[:dataset] == 'summary') ? true : false, :dataset_id => @raw_id.to_i).all
        #.reject{|e| @raw_id and @raw_id.to_i == e.dataset_id}
        # phenotypes_to_del = all_phenotypes - phenotypes_to_keep
        phenotypes_to_keep = all_phenotypes - phenotypes_to_del
        
#        logger.debug(phenotypes.map{|e| e.name})
        # get phenotype_ids
        h_phenotype_ids = {}
        phenotypes_to_keep.map{|p| h_phenotype_ids[p.id.to_s] = 1}

        # get dgrp lines
        #dgrp_lines = []
        h_pheno_sum = Basic.safe_parse_json(@study.pheno_sum_json, {}) 
        h_dgrp_lines_to_keep = {}
        h_pheno_sum.keys.each do |dgrp_line|
          h_pheno_sum[dgrp_line].each_key do |p_id|
            if h_phenotype_ids[p_id]
              h_dgrp_lines_to_keep[dgrp_line] = 1
            end
          end
        end
                       #.select{|p_id| !h_phenotype_ids[p_id.to_s]}.each do |p_id|
        #   dgrp_lines |= h_pheno_mean[p_id].keys
        #end
        #        logger.debug(h_dgrp_lines)
        
        # make hash 
        h_dgrp_lines ={}
        DgrpLine.where(:name => h_dgrp_lines_to_keep.keys).all.each do |d|
          h_dgrp_lines[d.id] = d 
        end

        #logger.debug("delete #{phenotypes_to_del.size}")
        #logger.debug("delete #{phenotypes_to_del.map{|e| e.name}.sort} phenotypes")
        phenotypes_to_del.each do |p|
          #          @log.push "delete phenotype #{p.id}"
          p.dgrp_line_studies.delete_all
          p.gwas_results.delete_all
          p.destroy
        end
        
        ## check if some dgrp_line_studies should be removed
        @study.dgrp_line_studies.each do |dgrp_line_study|
          if !h_dgrp_lines[dgrp_line_study.dgrp_line_id]
            #logger.debug("delete")
            @log.push "delete dgrp_line_study: #{dgrp_line_study.id} (#{(h_dgrp_lines[dgrp_line_study.dgrp_line_id]) ? h_dgrp_lines[dgrp_line_study.dgrp_line_id].name : dgrp_line_study.dgrp_line_id})"
            dgrp_line_study.destroy
          end
        end
        
        ## replace values in h
       # logger.debug(@h_pheno.to_json)
        @study.update({:pheno_json => @h_pheno.to_json})
       # logger.debug @log.to_json
    end
    
  end
  
  def parse_dataset

    if curator?

      threshold = 0.3 ## threshold for continuous / discrete
      
      data_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'studies'
      
      @h_pheno = Basic.safe_parse_json(@study.pheno_json, {})
      raw_ids = (@h_pheno['raw']) ? @h_pheno['raw'].keys.select{|k| @h_pheno['raw'][k]}.map{|e| e.to_i}.sort : [0]
      last_raw_id = raw_ids.last
      @raw_id = nil
      @h_existing_data = {}
      #@filename = ""
      
      if params[:dataset] == 'summary'
      #   @filename = @study.id.to_s + '_summary.tsv'
        @h_existing_data = @h_pheno['summary']
      elsif params[:dataset] == 'new'
        @raw_id = (last_raw_id) ? (last_raw_id + 1) : 1 
      #   @filename = @study.id.to_s + "_raw_#{@raw_id}.tsv"
      #      @h_existing_data = @h_pheno['raw'][@raw_id.to_s]
      elsif m = params[:dataset].match(/raw_(\d+)/)
        @raw_id = m[1]
        @h_existing_data = @h_pheno['raw'][@raw_id]
        #   @filename = @study.id.to_s + "_raw_#{@raw_id}.tsv"
      end
      
      @data = params[:file].read()
      @h_res = Parse.parse_tsv(@data, logger)
      
      @h_data = @h_res[:h_data]

      tmp_dgrp_lines = @h_data.keys
      tmp_dgrp_lines.map{|e|
        if m = e.match(/^\s*\w*_?(\d+)\s*$/)
          "DGRP_" + ("0" * (3-m[1].size)) + m[1]
        end
      }
      
      new_dgrp_lines = tmp_dgrp_lines - ((@h_existing_data) ? @h_existing_data.keys : [])
      existing_dgrp_lines = DgrpLine.where(:name => new_dgrp_lines).all
      new_dgrp_lines_not_in_db = new_dgrp_lines - existing_dgrp_lines.map{|e| e.name}
      removed_dgrp_lines = ((@h_existing_data) ? @h_existing_data.keys : []) - @h_data.keys
      
      h_existing_pheno = {}
      if @h_existing_data
        @h_existing_data.each_key do |dgrp_line|
          @h_existing_data[dgrp_line].keys.select{|k| k != 'sex'}.each do |k|
             h_existing_pheno[k] = 1
          end
        end
      end
      
      h_pheno = {}
      redundant_sex = false
      @h_data.each_key do |dgrp_line|
        if @h_data[dgrp_line]['sex'].sort != @h_data[dgrp_line]['sex'].uniq.sort
          redundant_sex = true
        end
        @h_data[dgrp_line].keys.select{|k| k != 'sex'}.each do |k|
          h_pheno[k] = 1
        end
      end

      if redundant_sex == true and params[:dataset] == 'summary'
        @h_res[:errors].push "Multiple lines found for the same DGRP line and the same sex, which is not possible for a summary dataset"
      end
      
      new_phenotypes = h_pheno.keys - h_existing_pheno.keys
      bad_new_phenotypes = Phenotype.where(:name => new_phenotypes).all.select{|e| e.study_id != @study.id or (params[:dataset] == 'summary' and e.is_summary == false) or (params[:dataset] != 'summary' and @raw_id != e.dataset_id)}.map{|e| e.name}
      removed_phenotypes = h_existing_pheno.keys - h_pheno.keys

      all_phenotypes = h_existing_pheno.keys | h_pheno.keys
      
      @diff = {
        :new_dgrp_lines => new_dgrp_lines,
        :new_dgrp_lines_not_in_db => new_dgrp_lines_not_in_db,
        :removed_dgrp_lines => removed_dgrp_lines,
        :new_phenotypes => new_phenotypes,
        :removed_phenotypes => removed_phenotypes,
        :bad_new_phenotypes => bad_new_phenotypes # redundant name already found in db
      }
      
      #    @h_diff_description={
      #      :new_dgrp_lines => "New DGRP lines",
      #      :new_dgrp_lines_not_in_db => "New DGRP lines not yet in DB",
      #      :removed_dgrp_lines => "Removed DGRP lines",
      #      :new_phenotypes => "New phenotypes",
      #      :removed_phenotypes => "Removed phenotypes",
      #      :bad_new_phenotypes => "Bad new phenotypes"
      #    }
      #
      #    @h_diff_css_class={
      #      :new_dgrp_lines => "success",
      #      :new_dgrp_lines_not_in_db => "warning",
      #      :removed_dgrp_lines => "warning",
      #      :new_phenotypes => "success",
      #      :removed_phenotypes => "warning",
      #      :bad_new_phenotypes => "danger"
      #    }
      #logger.debug(params[:integrate])
      #logger.debug(@diff[:bad_new_phenotypes].to_json)
      #logger.debug(@diff[:new_dgrp_lines_not_in_db].to_json)
      if params[:integrate] and @diff[:new_dgrp_lines_not_in_db].size == 0  #and @diff[:bad_new_phenotypes].size == 0 and @diff[:new_dgrp_lines_not_in_db].size == 0

        #logger.debug("integrate")
        
        ## delete phenotype associations
        Phenotype.where(:name => removed_phenotypes, :study_id => @study.id, :dataset_id => @raw_id).all.each do |p|
#          @study.phenotypes.delete(p)
          p.dgrp_line_studies.delete_all
          p.destroy
        end
        ## delete dgrp line associations
        removed_dgrp_line_studies = DgrpLineStudy.where(:id => DgrpLine.where(:name => removed_dgrp_lines).all.map{|e| e.id}).all
        removed_dgrp_line_studies.map{|e| e.phenotypes.delete_all}
        removed_dgrp_line_studies.destroy_all
                                     #.each do |d|
          #@study.dgrp_line_studies.delete(d)
      #  end

        ## all and update phenotypes
        puts "ALL PHENOTYPES: " + all_phenotypes.to_json
        h_pheno.keys.each do |phenotype_name|
          is_numeric = true
          vals = @h_data.keys.map{|k| @h_data[k][phenotype_name]}.flatten
          distinct_vals = vals.uniq
          is_continuous = (distinct_vals.size.to_f / vals.size > threshold) ? true : false
          @h_data.each_key do |dgrp_line|
            if @h_data[dgrp_line][phenotype_name]
              @h_data[dgrp_line][phenotype_name].each do |val|
                is_numeric = false if !val.is_a? Numeric and val != nil
              end
            end
          end
          is_continuous = false if is_numeric == false

          #double_checking the phenotype doesn't exist otherwise update it
          p = Phenotype.where(:name => phenotype_name,  :study_id => @study.id, :is_summary => ((params[:dataset] == 'summary') ? true : false), :dataset_id => @raw_id).first
          if !p
            p = Phenotype.new(:name => phenotype_name, :description => '', :study_id => @study.id, :is_summary => ((params[:dataset] == 'summary') ? true : false), :dataset_id => @raw_id, :is_numeric => is_numeric, :is_continuous => is_continuous)
            p.save
            Sunspot.index(p)
          else
            p.update(:is_numeric => is_numeric) #, :is_continuous => is_continuous) do not update is_continuous as it can be changed by curator
          end
        end
        
        ## add new dgrp_lines

        h_phenotypes={}
        h_phenotypes2 = {}
        Phenotype.where(:name => h_pheno.keys, :study_id => @study.id, :dataset_id => @raw_id).all.map{|e| h_phenotypes[e.name] = e; h_phenotypes2[e.id] = e}
        
        new_dgrp_lines.each do |dgrp_line_name|
          dgrp_line = DgrpLine.where(:name => dgrp_line_name).first
          if dgrp_line
            dgrp_line_study = DgrpLineStudy.where(:dgrp_line_id => dgrp_line.id, :study_id => @study.id).first
            if !dgrp_line_study
              dgrp_line_study = DgrpLineStudy.new(:dgrp_line_id => dgrp_line.id, :study_id => @study.id)
              dgrp_line_study.save
            end
            @h_data[dgrp_line_name].each_key do |phenotype_name|
              if @h_data[dgrp_line_name][phenotype_name] and @h_data[dgrp_line_name][phenotype_name].compact.size > 0
                dgrp_line_study.phenotypes << h_phenotypes[phenotype_name] if h_phenotypes[phenotype_name] and !dgrp_line_study.phenotypes.include? h_phenotypes[phenotype_name]
              end
            end
          end
        end
        
        ## integrate in JSON
        filename = ''
        if params[:dataset] == 'summary'
          @h_pheno['summary'] = @h_data
          filename = 'summary'
        elsif @raw_id #params[:dataset] == 'new' or params[:dataset] == 'raw'
          @h_pheno['raw']||={}
          @h_pheno['raw'][@raw_id] = @h_data
          filename = 'raw_' + @raw_id.to_s
        end
        @study.update(:pheno_json => @h_pheno.to_json)

        ## create directory if not exists
        Dir.mkdir  data_dir + @study.id.to_s if !File.exist? data_dir + @study.id.to_s
        
        ## write file on disk
        symlink = data_dir + @study.id.to_s + "#{@study.id}_#{filename}.tsv"

        last_upload = Upload.where(:filename => "#{@study.id}_#{filename}.tsv").order(:version_id).last
        version = (last_upload) ? (last_upload.version_id+1) : 1

        
        filepath =  data_dir + @study.id.to_s + "#{@study.id}_#{filename}.#{version}.tsv"
        #logger.debug("FILEPATH: " + filepath.to_s)
        File.open(filepath, 'w') do |f|
          f.write @data
        end

        File.delete symlink if File.exist? symlink
        File.symlink filepath, symlink
        u = Upload.new({:study_id => @study.id, :filename => "#{@study.id}_#{filename}.tsv", :version_id => version})
        u.save

        #update sums
        Basic.upd_sums(@study)

        #update sex_by_dgrp
        h_pheno_sum = Basic.safe_parse_json(@study.pheno_sum_json, {})
        h_sex = {}
        if h_pheno_sum
          h_pheno_sum.each_key do |dgrp_line|
            #  h_tmp[dgrp_line] ||= []
            #     h_tmp[dgrp_line] |= h_pheno[dgrp_line]['sex']
            h_pheno_sum[dgrp_line].keys.reject{|e| e == 'sex'}.each do |p|
              if h_pheno_sum[dgrp_line][p]
                h_pheno_sum[dgrp_line][p].each_index do |i|
                  h_sex[p] ||= {}
                  h_sex[p][dgrp_line] ||= []
                  h_sex[p][dgrp_line].push h_pheno[dgrp_line]['sex'][i] if h_pheno[dgrp_line] and h_pheno[dgrp_line][p] and h_pheno[dgrp_line][p][i] and h_pheno[dgrp_line][p][i][0]
                end
              end
            end
          end
        end
        h_sex.each_key do |p|
          h_phenotypes2[p.to_i].update_attribute(:sex_by_dgrp, h_sex[p].to_json)
        end
        
        #update stats
        cmd = "rails compute_stats"
        `#{cmd}`
        
      end
      
      render :partial => 'preparse_dataset'
    else
      render :plain => "Not allowed"
    end
  end
  
  def upload_form
    render :partial => 'upload_form'
  end
  
  def get_file
    if !params[:namespace] or ['studies', 'gwas', 'tmp', 'downloads'].include? params[:namespace]
      namespace = params[:namespace] || 'studies'
      @file_dir = Pathname.new(APP_CONFIG[:data_dir]) + namespace
    end
    filepath = nil
    filename = nil
    
    if namespace == 'studies' and @study and params[:name]
      filepath = @file_dir + @study.id.to_s + (@study.id.to_s + "_" + params[:name])
    elsif ['gwas', 'downloads', 'tmp'].include?(namespace) and params[:name]
      filepath = @file_dir + params[:name]
    end
    #    ext =  filename.split(".").last                                                                                                                         
    
    #    if readable?(@study)
    if filepath and File.exist? filepath
      #          fname = (params[:type] == 'archive') ? (params[:key] + ".tgz") : [@project.key, step_name,  run_id, filename].compact.join("_")           
      fname = filepath.basename.to_s
      send_file filepath.to_s, type: params[:content_type] || 'text', #'application/octet-stream',
                x_sendfile: true, buffer_size: 512, disposition: (!params[:display]) ? ("attachment; filename=" + fname) : ''
    #      Basic.add_history("Download #{params[:p]}", @project, current_user, {:admin_only => true}) if params[:dl] == "1"
    else
      render :plain => "This file doesn't exist (#{filepath})."
    end
    #    else
    #      render :plain => "This file is not readable."
    #    end
    
  end

  
  # GET /studies or /studies.json
  def index
    @h_nber_studies_by_status = {}
    @h_statuses = {}
    Status.all.map{|s|
      @h_statuses[s.id] = s
      @h_nber_studies_by_status[s.id] = 0
    }
#    @h_dgrp_statuses ={}
#    DgrpStatus.all.map{|e| @h_dgrp_statuses[e.id]=e}

    if admin?
      @studies = Study.all
    else
      @studies = Study.joins(:status).where(:status => {:name => ['submitted', 'accepted', 'integrated']})
    end

    @h_users = {}
    User.all.map{|u| @h_users[u.id] = u}
    
    @categories = Category.all
    @h_cats ={}
    @categories.map{|c| @h_cats[c.id] = c}
    @h_cats_by_study = {}
    @studies.map{|s|
      @h_cats_by_study[s.id]= []
      @h_nber_studies_by_status[s.status_id] +=1
    }
    Category.joins(:studies).select("categories.id as category_id, studies.id as study_id").map{|e| @h_cats_by_study[e.study_id]||=[]; @h_cats_by_study[e.study_id].push(e.category_id)} #.where(["study_id in (?)",  @studies.map{|s| s.id}).all #.map{|e|  @h_cats_by_study[e.study_id].push(e.category_id)}

  end

  # GET /studies/1 or /studies/1.json
  def show

    @h_units = {}
    Unit.all.map{|u| @h_units[u.id] = u}
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    @h_dgrp_statuses ={}
    DgrpStatus.all.map{|e| @h_dgrp_statuses[e.id]=e}

    h_tmp_phenotypes = {}
    h_tmp_dgrp_lines = {}
    
    @h_stats = {"sex" => {}}
    @h_pheno = Basic.safe_parse_json(@study.pheno_json, {})
    if  @h_pheno['summary']
      @h_pheno['summary'].each_key do |dgrp_line|
        h_tmp_dgrp_lines[dgrp_line] = 1
        @h_pheno['summary'][dgrp_line].keys.select{|e| e!= 'sex'}.map{|e| h_tmp_phenotypes[e]=1}
        @h_pheno['summary'][dgrp_line]['sex'].map{|s|
          @h_stats["sex"][s] ||= 0
          @h_stats["sex"][s] += 1
        }
      end
    end
    if  @h_pheno['raw']
      @h_pheno['raw'].each_key do |dataset_id|
        @h_pheno['raw'][dataset_id].each_key do |dgrp_line|
          h_tmp_dgrp_lines[dgrp_line] = 1
          @h_pheno['raw'][dataset_id][dgrp_line].keys.select{|e| e!= 'sex'}.map{|e| h_tmp_phenotypes[e]=1}
          @h_pheno['raw'][dataset_id][dgrp_line]['sex'].map{|s|
            @h_stats["sex"][s] ||= 0
            @h_stats["sex"][s] += 1
          }
        end
      end
    end
    #logger.debug(h_tmp_phenotypes)
    phenotypes = Phenotype.where(:study_id => @study.id, :name => h_tmp_phenotypes.keys).all.to_a
    @h_phenotypes = {}
    phenotypes.map{|p| @h_phenotypes[[p.dataset_id, p.name]] = p}

    @h_dgrp_lines = {}
    dgrp_lines = DgrpLine.where(:name => h_tmp_dgrp_lines.keys).all
    dgrp_lines.map{|d| @h_dgrp_lines[d.name] = d}

    
    respond_to do |format|
      format.html { render }
      format.json {
        study = @study.attributes
        ["pheno", "pheno_mean", "pheno_median", "pheno_sum"].each do |e|
          study[e] = Basic.safe_parse_json(study[(e + "_json")], {})
          study.delete(("#{e}_json"))
        end
        render :json => study.to_json
      }
    end

  end

  # GET /studies/new
  def new
    @study = Study.new
  end

 # GET /studies/1/edit
  def edit
    
    if !curator?
      redirect_to unauthorized_path
    else
      @h_dgrp_statuses ={}
      DgrpStatus.all.map{|e| @h_dgrp_statuses[e.id]=e}

      @h_pheno = Basic.safe_parse_json(@study.pheno_json, {})
       @h_stats = {"sex" => {}}
       h_tmp_dgrp_lines = {}
       h_tmp_phenotypes = {}
       if @h_pheno['summary']
         @h_pheno['summary'].each_key do |dgrp_line|
           h_tmp_dgrp_lines[dgrp_line] = 1
           @h_pheno['summary'][dgrp_line].keys.select{|e| e!= 'sex'}.map{|e| h_tmp_phenotypes[e]=1}
           @h_pheno['summary'][dgrp_line]['sex'].map{|s|
             @h_stats["sex"][s] ||= 0
             @h_stats["sex"][s] += 1
           }
         end
       end
       if @h_pheno['raw']
         @h_pheno['raw'].each_key do |dataset_id|
           if  @h_pheno['raw'][dataset_id]
             @h_pheno['raw'][dataset_id].each_key do |dgrp_line|
               h_tmp_dgrp_lines[dgrp_line] = 1
               @h_pheno['raw'][dataset_id][dgrp_line].keys.select{|e| e!= 'sex'}.map{|e| h_tmp_phenotypes[e]=1}
               @h_pheno['raw'][dataset_id][dgrp_line]['sex'].map{|s|
                 @h_stats["sex"][s] ||= 0
                 @h_stats["sex"][s] += 1
               }
             end
           end
         end
       end
       #logger.debug(h_tmp_phenotypes)
       phenotypes = Phenotype.where(:study_id => @study.id, :name => h_tmp_phenotypes.keys).all.to_a
       @h_phenotypes = {}
       phenotypes.map{|p| @h_phenotypes[[p.dataset_id, p.name]] = p}
       @h_dgrp_lines = {}
       dgrp_lines = DgrpLine.where(:name => h_tmp_dgrp_lines.keys).all
       dgrp_lines.map{|d| @h_dgrp_lines[d.name] = d}
       
    end
  end

  # POST /studies or /studies.json
  def create
    @study = Study.new(study_params)
    @study.status_id = 1
    doi = nil
    if m =  @study.doi.strip.match(/(10\.\d{4,9}\/[\-._;()\/\:a-zA-Z0-9]+)$/)
      doi = m[1]
    end
    h = CustomFetch.doi_info(doi)
    existing_study = Study.where(:doi => doi).first
    h[:submitter_id] = current_user.id if current_user
    
    respond_to do |format|
      if doi and !existing_study and h[:first_author] and @study.save
       # format.html { redirect_to study_url(@study), notice: "Study was successfully created." }
        @study.update(h)
        format.html {
        render :plain => "<span class='text-success'>Successfully submitted (<a href='" + study_path(@study) + "' target='_blank'>see submission</a>)!</span>"
         }
    #    format.json { render :show, status: :created, location: @study }
      elsif existing_study
        format.html { #render :new, status: :unprocessable_entity
          render :plain => "<span class='text-warning'>This reference already exists (<a href='" + study_path(existing_study) + "' target='_blank'>see here</a>)!</span>"
        }
      elsif doi
          format.html { #render :new, status: :unprocessable_entity              
          render :plain => "<span class='text-danger'>DOI #{doi} is not a valid reference!</span>"
        }
      else
        format.html { #render :new, status: :unprocessable_entity  
          render :plain => "<span class='text-danger'>Not a valid reference!</span>"
        }

#        format.json { render json: @study.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /studies/1 or /studies/1.json
  def update
    h = {}
    h[:validator_id] = current_user.id if [1, 2].include? @study.status_id and !@study.validator_id and study_params[:status_id] == 4
    respond_to do |format|

      authors = []
      format_ok = 1
      begin
       authors = JSON.parse(study_params[:authors_json])
      rescue Exception => e
        format_ok = 0
      end
      if authors.size > 0
        first_author = authors.first
        h[:first_author] = first_author['lname']
        h[:authors] = "#{first_author['lname']}" + ((authors.size > 1) ?  " et al." : '')
      end
      #logger.debug(h.to_json)
      #logger.debug(format_ok)
      #logger.debug(curator?)
      if format_ok == 1 and curator? and @study.update(study_params)
        if h.keys.size > 0
          @study.update(h)
        end
        format.html { redirect_to study_url(@study), notice: "Study was successfully updated." }
        format.json { render :show, status: :ok, location: @study }
      else
        format.html { render :edit, notice: "Format #{format_ok}", status: :unprocessable_entity }
        format.json { render json: @study.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /studies/1 or /studies/1.json
  def destroy
    if admin?
      @study.phenotypes.destroy_all
      @study.dgrp_line_studies.destroy_all
      @study.destroy
    end
    respond_to do |format|
      format.html { redirect_to studies_url, notice: "Study was successfully destroyed.",  method: :get}
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_study
      @study = Study.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def study_params
      params.fetch(:study).permit(:title, :authors_json, :abstract, :journal_id, :pmid, :doi, :first_author, :status_id, :submitter_id, :validator_id, :volume, :issue, :comment, :description, :repository_identifiers)
    end
end
