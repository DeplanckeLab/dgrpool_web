class PhenotypesController < ApplicationController
  before_action :set_phenotype, only: %i[ show edit update destroy gwas_analysis compute_correlation]

  
  def get_gwas_boxplot
    
    #    @phenotype.geno_string
    @snp = Snp.where(:identifier => params[:snp_id]).first
    @phenotype = Phenotype.where(:id => params[:phenotype_id]).first
    
    @h_traces = {} #{:y => []}
    @dgrps = []
    @geno_table = []
    @h_res = {}
    @h_dgrp_lines = {}
    
    h_legend = {'0' => "Reference (#{helpers.display_variant(@snp.ref)})", '2' => "Variant (#{helpers.display_variant(@snp.alt)})"}
    
    phenotype_key = nil
    @phenotype_name = ''
    @h_pheno_sum = nil
    if @phenotype
      @study = @phenotype.study      
      phenotype_key = @phenotype.id.to_s
      #logger.debug("PHENOTYPE_KEY: " + phenotype_key.to_s + ".")
      @phenotype_name = @phenotype.name
      @h_pheno_sum = Basic.safe_parse_json(@study.pheno_sum_json, {})
      dgrp_lines = @h_pheno_sum.keys
      first_dgrp_line =  dgrp_lines.first
    elsif params[:phenoname] and params[:md5] 
      tmp_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + params[:md5]
      dataset_sum_file = tmp_dir + 'dataset_sum.json'
      phenotype_key = params[:phenoname]
      @phenotype_name = params[:phenoname]
      if File.exist? dataset_sum_file
        pheno_sum_json = File.read(dataset_sum_file)
        @h_pheno_sum = Basic.safe_parse_json(pheno_sum_json, {})
      end
    end
    
    if @snp
      
      @dgrps = DgrpLine.where(:dgrp_status_id => [1,2]).all.sort{|a, b| a.name <=> b.name}
      @geno_table = @snp.geno_string.split("")
      @geno_table.each_index do |i|
        t = @geno_table[i]
        if t!='.'
          @h_res[t]||=[]
          @h_res[t].push @dgrps[i]
        end
      end
      
      if @h_pheno_sum
        dgrp_lines = @h_pheno_sum.keys
      #  logger.debug("DGRP_LINES: " + dgrp_lines.to_json)
        first_dgrp_line = dgrp_lines.first
        list_sex = @h_pheno_sum[first_dgrp_line]['sex']
        if list_sex
          list_sex.each_index do |sex_i|
            sex = list_sex[sex_i]
            if sex == params[:sex]
              
              @h_traces[sex]||=[]            
              @h_dgrp_lines = {}
              
              dgrp_lines.map{|d| @h_dgrp_lines[d] = @h_pheno_sum[d][phenotype_key][sex_i]}
             # logger.debug("H_DGRP_LINES: " + sex_i.to_s + ": " + @h_pheno_sum["2765"].to_json)
              @h_res.each_key do |k|
                trace = {
                  :y => @h_res[k].map{|e| (@h_dgrp_lines[e.name]) ? @h_dgrp_lines[e.name][0] : nil}.compact,
                  :text => @h_res[k].map{|e| (@h_dgrp_lines[e.name]) ? e.name : nil}.compact,
                  :name => h_legend[k],
                  :type => 'box',
                  :jitter => 0.3,
                  :pointpos => -1.8,
                  :boxpoints => 'all'
                }
                @h_traces[sex].push trace
              end
            end
          end
        end
      end
    end

    #    if params[:layout]
    #      render "get_gwas_boxplot", :layout => "min"
    #    else
    render :partial => "get_gwas_boxplot"
    #    end
  end
  
  def compute_correlation

    params[:only_curated_studies] ||= '1'
    @h_phenotypes = {}
    Phenotype.all.map{|p| @h_phenotypes[p.id] = p}
    @h_studies = {}
    Study.all.map{|s| @h_studies[s.id] = s}
    @h_sex = {'F' => 'female', 'M' => 'male', 'NA' => 'unclassified'}
    
    t_header = ["DGRP", 'sex', @phenotype.name] #.join("\t") + "\n"
    study = @phenotype.study
    h_pheno = Basic.safe_parse_json(study.pheno_sum_json, {})
    first_dgrp_line = h_pheno.keys.first
    @list_sex = h_pheno[first_dgrp_line]['sex'] #.sort{|a, b|  @h_res[@list_sex[i]][:res].size <=>  @h_res[@list_sex[i]][:res].size}
 
  #  h_content={}
  # 
  #  @h_res = {}
  #  @list_sex.each_index do |i|
  #    h_content[@list_sex[i]] = h_pheno.keys.select{|k| h_pheno[k][@phenotype.id.to_s]}.map{|dgrp_line| "#{dgrp_line}\t" + ((h_pheno[dgrp_line][@phenotype.id.to_s][i]) ? h_pheno[dgrp_line][@phenotype.id.to_s][i][0].to_s : '')}.join("\n")
 ##     @h_res[@list_sex[i]] = Basic.compute_correlation(t_header, h_content[@list_sex[i]])
 #   end

    content = []
    @list_sex.each_index do |i|
      content += h_pheno.keys.select{|k| h_pheno[k][@phenotype.id.to_s]}.map{|dgrp_line| "#{dgrp_line}\t#{@list_sex[i]}\t" + ((h_pheno[dgrp_line][@phenotype.id.to_s][i]) ? h_pheno[dgrp_line][@phenotype.id.to_s][i][0].to_s : '')}
    end

    @h_res = Basic.compute_correlation(t_header, content.join("\n")) 

    ## filter results
 
    @h_res[:res].each_key do |s|
      tmp_res = [] 
      @h_res[:res][s].each do |t|
        if params[:only_curated_studies] != '1' or (@h_phenotypes[t[0].to_i] and @h_studies[@h_phenotypes[t[0].to_i].study_id].status_id == 4)
          tmp_res.push t
        end
      end
      @h_res[:res][s] = tmp_res
    end
    
    
    @ordered_list_sex = (0 .. @list_sex.size-1).sort{|a, b| @h_res[:res][@list_sex[b]].size <=>  @h_res[:res][@list_sex[a]].size}
    @cur_sex = params[:sex] || @list_sex[@ordered_list_sex.first]
#    render "home/compute_my_pheno_correlation"
    
  end

  def gwas_analysis

    @h_impact = {
      'HIGH' => 'danger',
      'MODERATE' => 'warning',
      'LOW' => 'secondary',
      'MODIFIER' => 'info'
    }
    
    
    @study = @phenotype.study
   
    @gwas_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'gwas'

    @h_output = {}
    output_file = @gwas_dir + 'gwas_output.json' 
    if File.exist? output_file
      @h_output = Basic.safe_parse_json(File.read(output_file), {})
    end
    h_sum = Basic.safe_parse_json(@study.pheno_sum_json, {})
    first_dgrp_line = h_sum.keys.first
    @list_sex = h_sum[first_dgrp_line]["sex"]      
    @cur_sex = params[:sex] || @list_sex.first

    @h_var_types = {}
    VarType.all.each do |vt|
      @h_var_types[vt.name] = vt
    end

    
    #S105_dead_F.glm.linear.top_0.01.annot.tsv.gz
    #S105_dead_F.manhattan.png                   
    #S105_dead_F.pheno.dgrp2.csv                 
    #S105_dead_F.pheno.plink2.tsv                
    #S105_dead_F.qqplot.png                      
    #S105_dead_M.cov.anova.txt  

    @h_covariate_mapping = {
      "wolba" => 2347,
      "In_2L_t" => 1520,
      "In_2R_NS" => 1521,
      "In_3R_P" => 1532,
      "In_3R_K" => 1533,
      "In_3R_Mo" => 1534
    }
    
    @h_files = {}
    @anova = {}
    @annot = {}
    @h_snps = {}
    @h_gwas_results={}
    @all_snps = []
    @h_snps = {}
    @h_nber_res = {}
    @list_sex.each do |s|
      prefix = "S#{@study.id}_#{@phenotype.id}_#{s}"
      @h_files[s] = {
        :qqplot => "#{prefix}.qqplot.png",
        :manhattan => "#{prefix}.manhattan.png",
        :dgrp2 => "#{prefix}.pheno.dgrp2.csv",
        :plink2 => "#{prefix}.pheno.plink2.tsv",
        :anova => "#{prefix}.cov.anova.txt",
        :annot => (File.exist?(@gwas_dir + "#{prefix}.glm.linear.top_0.01.annot.tsv.gz")) ? "#{prefix}.glm.linear.top_0.01.annot.tsv.gz" : "#{prefix}.glm.logistic.hybrid.top_0.01.annot.tsv.gz"#,
#        :done => "done"
      }
      
    #  @h_snps = {}
#      @gwas_results = GwasResult.where().all
      @h_gwas_results[s] = []
      @h_nber_res[s] = -1
      if File.exist?(@gwas_dir + @h_files[s][:annot])
        #logger.debug("zless #{@gwas_dir + @h_files[s][:annot]} | wc -l")
        #logger.debug(`zless #{@gwas_dir + @h_files[s][:annot]} 2>&1`)
        @h_nber_res[s] = `zless #{@gwas_dir + @h_files[s][:annot]} | wc -l`.to_i - 1 
     
        Zlib::GzipReader.open(@gwas_dir + @h_files[s][:annot]) {|gz|
          i=0
          gz.each_line do |l|
            if i > 0
              @h_gwas_results[s].push l.split("\t")
            end
            i+=1
            break if i> 1000
          end
        }
      end
      tmp_str = "{" + Snp.where(:identifier => @h_gwas_results[s].map{|e| e[2]}).all.map{|snp|
        #  @h_snps[s][snp.identifier] = snp.
        '"' + ((snp.identifier) ? snp.identifier : 'NA') + '":' + ((snp.annots_json) ? snp.annots_json : "null") 
      }.join(",") + "}"
      @h_snps.merge!(Basic.safe_parse_json(tmp_str, {}))
      # @all_snps.push tmp_str
     # tmp_h = JSON.parse(tmp_str)
     # tmp_h.each_key do |k|
     #   @h_snps[k] = tmp_h[k] # .merge!(JSON.parse(tmp_str))
     #   logger.debug "#{k} => #{tmp_h[k]}" if k == 'X_8149138_SNP'
     # end
      #Anova Table (Type III tests)
      #
      #Response: S14_2739_M
      #                 Sum Sq  Df  F value  Pr(>F)
      #(Intercept)      5.3368   1 306.1103 < 2e-16 ***
      #factor(wolba)    0.0000   1   0.0020 0.96478
      #factor(In_2L_t)  0.0108   2   0.3104 0.73382
      #factor(In_2R_NS) 0.1053   2   3.0201 0.05305 .
      #factor(In_3R_P)  0.0145   2   0.4164 0.66048
      #factor(In_3R_K)  0.0206   2   0.5902 0.55604
      #factor(In_3R_Mo) 0.0552   2   1.5824 0.21033
      #Residuals        1.8306 105
      @anova[s]= []
#      @anova_content = File.read(@gwas_dir + @h_files[s][:anova])
      nber_lines = 0
      if File.exist?(@gwas_dir + @h_files[s][:anova])
        File.open(@gwas_dir + @h_files[s][:anova], 'r') do |f|
          flag = 0
          while (l = f.gets) do
            if flag == 0 and l.match(/^\(Intercept\)/)
              flag = 1
            elsif l.match(/^Residuals/)
              flag = 2
            else
              if flag == 1
#                if l.match(/^factor\(.+?\).+?(.|\*)+/)
                t = l.split(/[\s]+/)
                if t.size > 3
                  nber_lines +=1
                end

                if t[5] and n = t[5].match(/(.|\*+)$/)
                  if m = t[0].match(/^factor\((.+?)\)/)
                    level = 0
                    if n[1] == '.'
                      level = 1
                    else
                      level = n[1].size + 1
                    end
                    @anova[s].push [m[1], t[1], t[2], t[3], t[4], level]
                  end
                end
              end
            end
          end
        end
      end
      if  @anova[s].size == 0 and nber_lines == 0
        @anova[s] = nil
      end

      @annot[s] = []

#      @annot_content = ''
#      infile = @gwas_dir + @h_files[s][:annot]
#       logger.debug infile
#       if File.exist?(infile)
#        gz = Zlib::GzipReader.new(infile)
#        gz.each_line do |line|
#          @annot_content+= line
#        end
#        @annot_content = gz.read
#      end
    end
  end
  
  def autocomplete
    to_render = []
    final_list=[]
    
    q = params[:q].downcase
    
#    if !q.empty?

    
    dgrp_line_studies = []
    h_sex_by_dgrp = {}
    if params[:phenotype_id] != ''
      phenotype = Phenotype.where(:id => params[:phenotype_id]).first
      h_sex_by_dgrp = Basic.safe_parse_json(phenotype.sex_by_dgrp, {})
      dgrp_line_studies = phenotype.dgrp_line_studies if phenotype
    end
    #logger.debug("DGRP_LINE_STUDIES:" + dgrp_line_studies.map{|e| e.id}.to_json)
    query = Phenotype.search do
      fulltext "*" + params[:q].gsub(/\$\{jndi\:/, '').gsub(/[+\-"\/]/) { |c| "\\" + c } + "*", :fields => [:name, :description, :study_authors]
      with(:dgrp_line_ids,  dgrp_line_studies.map{|e| e.dgrp_line_id}.uniq) if params[:phenotype_id] != ''
      with(:has_dgrp_line_studies, true)
      with(:integrated_study, true) if params[:only_integrated_studies] == "1"
      with(:is_numeric, true) if params[:is_numeric] == '1'
      with(:obsolete, false)
      #        with(:tax_id, (organisms.size > 0) ? organisms.map{|e| e.tax_id} : [])
      order_by("name_order", "asc") ## propose several sorts                                                                                                                                                                                                  
      paginate :page => 1, :per_page => 50
    end

    phenotypes = query.results
    h_res = {}
    i=0
    #Organism.where(:id => exps.map{|e| e.project_id}.uniq).all.map{|p| h_projects[p.id] = p}                                    
    h_studies = {}
    Study.where(:id => phenotypes.map{|p| p.study_id}.uniq).all.map{|e| h_studies[e.id] = e}
  
  
    phenotypes.each do |p|
      p
      h_sex_in_common = {}
      h_sex_by_dgrp2 = Basic.safe_parse_json(p.sex_by_dgrp, {})
#      if params[:phenotype_id] != ''
#        h_sex_by_dgrp.each_key do |k|
#          if h_sex_by_dgrp2[k]
#            in_common = h_sex_by_dgrp[k] & h_sex_by_dgrp2[k]
#            in_common.map{|e| h_sex_in_common[e] = 1 }
#          end
#        end
#      else        
        #        h_sex_in_common['NA']=1 if p.nber_sex_na and p.nber_sex_na > 0
        #        h_sex_in_common['M']=1 if p.nber_sex_male and p.nber_sex_male > 0
        #        h_sex_in_common['F']=1 if p.nber_sex_female and p.nber_sex_female > 0
      h_sex_by_dgrp2.each_key do |k|
        h_sex_by_dgrp2[k].map{|e|  h_sex_in_common[e] = 1 }
      end
 #     end
      
      to_render.push({:id => p.id, :label => "#{helpers.display_reference_short2(h_studies[p.study_id])}<span class='nodec'> #{p.name} #{(p.description != '') ? "(" + p.description + ")" : ''}</span>", :description => p.description, :is_summary => p.is_summary, :name => p.name + " (" + helpers.display_reference_short(h_studies[p.study_id]) + ")", :sex_list => h_sex_in_common.keys.sort})
      # ((o.description != '') ? " (#{o.common_name})" : "") + " [taxID:#{o.tax_id}]"})
      i+=1
    end
 #   end

    render :plain => to_render.to_json #to_render.sort{|a, b| [a[:label].downcase,a[:label]]  <=> [b[:label].downcase, b[:label]]}.to_json                                                                                                                           
  end

  
  # GET /phenotypes or /phenotypes.json
  def index
    params[:only_curated_studies]||="1"

    
    @phenotypes = (params[:all] == '1' or curator?) ?
                    ((params[:only_curated_studies] != '1' or params[:all] == '1') ? Phenotype.all : Phenotype.joins(:study).where(:study => {:status_id => 4}).all) :
                    ((params[:only_curated_studies] != '1' or params[:all] == '1') ? Phenotype.where(:obsolete => false).all : Phenotype.joins(:study).where(:obsolete => false, :study => {:status_id => 4}).all)
    @h_summary_types = {}
    SummaryType.all.map{|st| @h_summary_types[st.id] = st}
    @h_studies = {}
    Study.all.map{|s| @h_studies[s.id] = s}

    #    @h_nber_dgrp_line_studies ={}
    
    #    DgrpLineStudy.select("dgrp_line_study_id, phenotype_id").joins("join dgrp_line_studies_phenotypes on (dgrp_line_studies.id = dgrp_line_study_id)").all.map{|e| @h_nber_dgrp_line_studies[e[:phenotype_id]]||=0; @h_nber_dgrp_line_studies[e[:phenotype_id]]+=1}

      respond_to do |format|
        format.html {
          render }
        format.json { render :json => @phenotypes }
    end

    
    
  end

  
  # GET /phenotypes/1 or /phenotypes/1.json
  def show

    params[:nber_bins] ||= 100
    @h_sex = {'F' => 'female', 'M' => 'male', 'NA' => 'undefined sex'}
    @study = @phenotype.study
    @h_pheno = nil
    @h_figure_types = {}
    FigureType.all.map{|ft| @h_figure_types[ft.id] = ft}
    @h_figures = {}
    Figure.where(:study_id => @study.id, :phenotype_ids => @phenotype.id).each do |figure|
      figure_type = @h_figure_types[figure.figure_type_id].name
      @h_figures[figure_type.name.to_sym] = figure
    end
    tmp_h_pheno = Basic.safe_parse_json(@study.pheno_json, {})
    if @phenotype.is_summary == true
      @h_pheno = tmp_h_pheno['summary']
    else
      @h_pheno = tmp_h_pheno['raw'][@phenotype.dataset_id.to_s] if tmp_h_pheno['raw']
    end
    @h_pheno_mean = Basic.safe_parse_json(@study.pheno_sum_json, {})
#    @data_type = 'numeric'
    @max_num = 1
    @mean_vector = {}
    @median_vector = {}
    @sum_vector = {}
    @dgrp_lines = {}
#    @is_summary = true
    # get list of sex
    @sex_list = []
    @h_all_sex = {}
    @errors = []
    h_sex = {}
    if @h_pheno
      @h_pheno.each_key do |dgrp_line|
        tmp_sex = @h_pheno[dgrp_line]['sex']
        #      @is_summary = false if tmp_sex.size != tmp_sex.uniq.size
        tmp_sex.each_index do |i|
          @h_all_sex[tmp_sex[i]] = 1
          if @h_pheno[dgrp_line][@phenotype.name]
            if @h_pheno[dgrp_line][@phenotype.name][i]
              h_sex[tmp_sex[i]] = 1
            end
          else
            @errors.push "error not found data for #{dgrp_line} #{@phenotype.name}"
          end
        end
      end
    end
    @h_nas = {}
    @h_mean_values = {}
    @h_median_values = {}
    @h_sum_values = {}
    @sex_list = h_sex.keys.sort
    #logger.debug("SEX_LIST: " + @sex_list.to_json)
    params[:dgrp_order]||=@sex_list.first
    params[:dgrp_order_barplot]||= @sex_list.first
    params[:displayed_sum_type]||="0"
    
    @sex_list.each do |s|
      @mean_vector[s] = []
      @median_vector[s] = []
      @sum_vector[s] = []
      @dgrp_lines[s] = []
      @h_mean_values[s] = {}
      @h_median_values[s] = {}
      @h_sum_values[s] = {}
      @h_nas[s] = 0
    end
    @all_dgrp_lines = []
  
    undefined_sex = []
    phenotype_id = @phenotype.id.to_s
    
    if @h_pheno
      @h_pheno.keys.select{|dgrp_line| @h_pheno_mean[dgrp_line]}.each do |dgrp_line|
        tmp_sex = @h_pheno_mean[dgrp_line]['sex']
        tmp_sex.each_index do |i|

          if !@mean_vector[tmp_sex[i]]
            undefined_sex.push("#{tmp_sex[i]} in #{dgrp_line}")
          else
            if @h_pheno_mean[dgrp_line][phenotype_id] and @h_pheno_mean[dgrp_line][phenotype_id][i]   
              @mean_vector[tmp_sex[i]].push @h_pheno_mean[dgrp_line][phenotype_id][i][0]
              @h_mean_values[tmp_sex[i]][dgrp_line] = @h_pheno_mean[dgrp_line][phenotype_id][i][0]
              @median_vector[tmp_sex[i]].push @h_pheno_mean[dgrp_line][phenotype_id][i][1]
              @h_median_values[tmp_sex[i]][dgrp_line] = @h_pheno_mean[dgrp_line][phenotype_id][i][1]
              @sum_vector[tmp_sex[i]].push @h_pheno_mean[dgrp_line][phenotype_id][i][params[:displayed_sum_type].to_i]
              @h_sum_values[tmp_sex[i]][dgrp_line] = @h_pheno_mean[dgrp_line][phenotype_id][i][params[:displayed_sum_type].to_i]
              @dgrp_lines[tmp_sex[i]].push dgrp_line
            elsif @phenotype.is_numeric == false
              if @h_pheno[dgrp_line][@phenotype.name] and  @h_pheno[dgrp_line][@phenotype.name][i]
                @mean_vector[tmp_sex[i]].push @h_pheno[dgrp_line][@phenotype.name][i]
                @h_mean_values[tmp_sex[i]][dgrp_line] = @h_pheno[dgrp_line][@phenotype.name][i]
                @dgrp_lines[tmp_sex[i]].push dgrp_line
              else
                @h_nas[tmp_sex[i]]+=1
              end
            else
              @h_nas[tmp_sex[i]]+=1
            end
          end
        end
        if @h_pheno[dgrp_line][@phenotype.name]
          if @h_pheno[dgrp_line][@phenotype.name].size > @max_num
            @max_num =  @h_pheno[dgrp_line][@phenotype.name].size
          end
          # @h_pheno[dgrp_line][@phenotype.name].each do |v|
          #   @data_type = 'text' if !v.is_a? Numeric #match(/^-?\d+\.?\d*$/)
          # end
        end
      end
    end
    @dgrp_lines.each_key do |sex|
      @all_dgrp_lines |= @dgrp_lines[sex]
    end
    
    undefined_sex.uniq!
    @errors.push "Undefined sex: " +  undefined_sex.join(", ")
    
    #@ordered_dgrp_lines =[]
    @ordered_index = {}
    @global_ordered_index = {}
    @ordered_index_barplot = {}
    @global_ordered_index_barplot = {}

    if @phenotype.is_numeric == true
      @sex_list.each do |s|
        @ordered_index[s] = (0 .. @dgrp_lines[s].size-1).to_a.sort{|a, b| @median_vector[s][a] <=> @median_vector[s][b]}
        @global_ordered_index[s] = (0 .. @all_dgrp_lines.size-1).to_a.sort{|a, b| (@h_median_values[s][@all_dgrp_lines[a]] || 0) <=> (@h_median_values[s][@all_dgrp_lines[b]] || 0)}
        @ordered_index_barplot[s] = (0 .. @dgrp_lines[s].size-1).to_a.sort{|a, b| @sum_vector[s][a] <=> @sum_vector[s][b]}
        @global_ordered_index_barplot[s] = (0 .. @all_dgrp_lines.size-1).to_a.sort{|a, b| (@h_sum_values[s][@all_dgrp_lines[a]] || 0) <=> (@h_sum_values[s][@all_dgrp_lines[b]] || 0)}
      end
    end

    #logger.debug("GLOBAL: #{@global_ordered_index.to_json}")
    
    @bin_size = nil
    @global_min = nil
    @global_max = nil
    if @phenotype.is_numeric == true
      @sex_list.each do |s|
        min = @mean_vector[s].min.to_f
        max = @mean_vector[s].max.to_f
        if min and max
          tmp_bin_size = ((max - min).to_f / params[:nber_bins].to_f) #(@mean_vector[s].size/20))
          @bin_size = tmp_bin_size if !@bin_size or @bin_size < tmp_bin_size and @bin_size != 0
          @global_min = min if !@global_min or min < @global_min
          @global_max = max if !@global_max or max > @global_max
        end
      end
    end
  end

  # GET /phenotypes/new
  def new
    @phenotype = Phenotype.new
  end

  # GET /phenotypes/1/edit
  def edit
    if !curator?
      redirect_to unauthorized_path
    end
  end

  # POST /phenotypes or /phenotypes.json
  def create
    @phenotype = Phenotype.new(phenotype_params)
    @phenotype.user_id = current_user.id
    
    respond_to do |format|
      if curator? and @phenotype.save
        format.html { redirect_to phenotype_url(@phenotype), notice: "Phenotype was successfully created." }
        format.json { render :show, status: :created, location: @phenotype }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @phenotype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /phenotypes/1 or /phenotypes/1.json
  def update
    data_dir = Pathname.new(APP_CONFIG[:data_dir])
    prev_name = @phenotype.name

    already_existing_in_dataset = false
    existing =  Phenotype.where(:name => params[:phenotype][:name], :study_id => @phenotype.study_id, :dataset_id => @phenotype.dataset_id).all
    if existing.select{|e| e.id != @phenotype.id}.size > 0
      already_existing_in_dataset = true
      #logger.debug(existing.to_json)
    end
    
    respond_to do |format|
      if already_existing_in_dataset == false and curator? and @phenotype.update(phenotype_params)
     #   h_summary_types = {} 
     #    sum_type = nil
     #   if @phenotype.description.match(/mean/i)
     #     sum_type = "mean"
     #   elsif @phenotype.description.match(/median/i)
     #     sum_type = "median"
     #   elsif @phenotype.description.match(/sd/i) or @phenotype.description.match(/standard deviation/i)
     #     sum_type = "sd"
     #   elsif @phenotype.description.match(/cv/i) or @phenotype.description.match(/coef[^ ]* of variation/i)
     #     sum_type = 'cv'
     #   end
     #   summary_type = h_summary_types[sum_type]
        ##name changed
        if prev_name != @phenotype.name
          ## change in json
          symlink_filename = ''
          study = @phenotype.study
          h_pheno = Basic.safe_parse_json(study.pheno_json, {})
          if @phenotype.dataset_id == nil
            symlink_filename = "#{@phenotype.study_id}_summary.tsv"
            h_pheno['summary'] = Basic.upd_phenotype_name(h_pheno['summary'], prev_name, @phenotype.name)
          else
            symlink_filename = "#{@phenotype.study_id}_raw_#{@phenotype.dataset_id}.tsv"
            h_pheno['raw'][@phenotype.dataset_id.to_s] = Basic.upd_phenotype_name(h_pheno['raw'][@phenotype.dataset_id.to_s], prev_name, @phenotype.name)
          end
          
          study.update(:pheno_json => h_pheno.to_json)
          
          filepath = File.readlink(data_dir + 'studies' + study.id.to_s + symlink_filename)
          
          ##change in file
          tmp_filename = "tmp_#{@phenotype.id}_#{current_user.id}.tsv"
          
          File.open(data_dir + tmp_filename, 'w') do |fw|
            File.open(filepath, 'r') do |f|
              header = f.gets.chomp
              t_header = header.split("\t")
              fw.write(t_header.map{|e| (e == prev_name) ? @phenotype.name : e}.join("\t") + "\n")
              while (l = f.gets) do
                fw.write(l)
              end
            end
          end
          FileUtils.move(data_dir + tmp_filename, filepath)

        end
        Basic.upd_sums(@phenotype.study)
        
        format.html { redirect_to phenotype_url(@phenotype), notice: "Phenotype was successfully updated." }
        format.json { render :show, status: :ok, location: @phenotype }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @phenotype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phenotypes/1 or /phenotypes/1.json
  def destroy
    if admin?
      @phenotype.dgrp_line_studies.delete_all
      @phenotype.gwas_results.delete_all
      @phenotype.destroy
    end
    respond_to do |format|
      format.html { redirect_to phenotypes_url, notice: "Phenotype was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phenotype
      @phenotype = Phenotype.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def phenotype_params
      params.fetch(:phenotype).permit(:name, :description, :obsolete, :is_continuous, :is_numeric, :summary_type_id, :unit_id)
    end
end
