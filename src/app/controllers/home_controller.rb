class HomeController < ApplicationController

  def upd_export
    `rails create_export`
  end
  
  def welcome

    @categories = Category.all.to_a
    @h_categories = {}
    @categories.each do |c|
      @h_categories[c.id] = c
    end
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.name] = s}
    @category_ids = @categories.sort!{|a, b| (b.nber_studies || 0) <=> (a.nber_studies || 0)}.map{|e| e.id}
    stats_file = Pathname.new(APP_CONFIG[:data_dir]) + 'stats.json'
    @h_stats = Basic.safe_parse_json(File.read(stats_file), {})
  end

  def get_gwas_results

    phenoname = params[:phenoname]#.gsub(/[^a-zA-Z0-9]+/, '_')
   # s = params[:sex]
    @md5 = params[:md5]
    
    @h_impact = {
      'HIGH' => 'danger',
      'MODERATE' => 'warning',
      'LOW' => 'secondary',
      'MODIFIER' => 'info'
    }

    @study = Study.find(20) ## random_study to use get_file method from Study object

    @gwas_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'gwas'
    @tmp_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp'
    
    output_file = @tmp_dir + @md5 + 'gwas_output.json'
    @h_output = {}
    if File.exist? output_file
      @h_output = Basic.safe_parse_json(File.read(output_file), {})
    end

    #s    h_sum = Basic.safe_parse_json(@study.pheno_sum_json, {})
#    first_dgrp_line = h_sum.keys.first
#    @list_sex = h_sum[first_dgrp_line]["sex"]
    @list_sex = params[:list_sex].split(",")
    @cur_sex = params[:sex] || @list_sex.first

    @h_var_types = {}
    VarType.all.each do |vt|
      @h_var_types[vt.name] = vt
    end

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
 #   @h_md5s={}
    
    @list_sex.each do |s|
      prefix = "#{@md5}/#{phenoname}_#{s}"
      @h_files[s] = {
        :qqplot => "#{prefix}.qqplot.png",
        :manhattan => "#{prefix}.manhattan.png",
        :dgrp2 => "#{prefix}.pheno.dgrp2.csv",
        :plink2 => "#{prefix}.pheno.plink2.tsv",
        :anova => "#{prefix}.cov.anova.txt",
        #mn_Longevity_F.glm.linear.top_0.01.annot.tsv.gz
        :annot => (File.exist?(@tmp_dir + "#{prefix}.glm.linear.top_0.01.annot.tsv.gz")) ? "#{prefix}.glm.linear.top_0.01.annot.tsv.gz" : "#{prefix}.glm.logistic.hybrid.top_0.01.annot.tsv.gz",
        :done => "#{@md5}/done"
      }
#      @h_md5s[s] = @md5
      #  @h_snps = {}                                                                                                                                                                                                               
      #      @gwas_results = GwasResult.where().all                                                                                                                                                                                     
      @h_gwas_results[s] = []
      @h_nber_res[s] = -1
      if File.exist? @tmp_dir + @h_files[s][:annot]
        @h_nber_res[s] = `zless #{@tmp_dir + @h_files[s][:annot]} | wc -l`.to_i - 1
        Zlib::GzipReader.open(@tmp_dir + @h_files[s][:annot]) {|gz|
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
      
      @anova[s]= []
      nber_lines = 0
      #      @anova_content = File.read(@gwas_dir + @h_files[s][:anova])                                                                                                                                                                
      if File.exist?(@tmp_dir + @h_files[s][:anova])
        File.open(@tmp_dir + @h_files[s][:anova], 'r') do |f|
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
      
    end
    @annot = []
    
    
    render :partial => 'phenotypes/all_gwas_analysis', :locals => {:phenotype => nil, :h_output => @h_output, :h_files => @h_files, :anova => @anova, :h_gwas_results => @h_gwas_results, :output_dir => @tmp_dir, :download_namespace => 'tmp', :md5 => @md5}
    
  end
  
  def check_pheno

  end

  def compute_my_pheno_correlation


    @h_res = {}

    if params[:file]

      file_max_size = 2000000

      if params[:file].size >= file_max_size
        @h_res[:errors] = ["This file is too big (#{params[:file].size.to_f/1000000}Mb). Only files smaller than 2Mb are accepted"]
      else
        #      tmp_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp'
        #      @md5s =  Dir.entries(tmp_dir).map{|e| m = e.match(/(\w+)\.tmp/); ((m and m[1]) ? m[1] : nil)}.compact.select{|e| File.exist?(tmp_dir + e + 'output.json')  and (!File.exist?(tmp_dir + e + 'gwas_output.json'))}
        
        dgrp_lines = DgrpLine.all
        @h_dgrp_lines = {}
        dgrp_lines.map{|d| @h_dgrp_lines[d.name] = 1}
        
        #logger.debug("File size: #{params[:file].size}")
        @data = ""
        @data = params[:file].read()
        @h_res = Parse.parse_user_tsv(@data, logger, false)
        logger.debug(@h_res.to_json)
        missing_dgrp_lines = []
        tmp_dgrp_lines = []
         tmp_dgrp_lines_by_sex = {}
        @h_sex_color.each_key do |sex|
          tmp_dgrp_lines_by_sex[sex] = []
        end
        # logger.debug("MATRIX:" + @h_res[:matrix].to_json)
        logger.debug( @h_res[:sex_list])
        h_sums = Basic.upd_dataset_sums(nil, nil, @h_res[:h_pheno], {}, @h_res[:sex_list], logger)
        @h_sex_color.each_key do |sex|
          if @h_res[:dgrp_lines_by_sex][sex]
            @h_res[:dgrp_lines_by_sex][sex].each do |e|
              if (m = e.match(/^\s*\w*?_?0*(\d+)\s*$/))            
                tmp_dgrp_lines_by_sex[sex].push ("DGRP_" + ("0" * (3-m[1].size)) + m[1])
              else
                tmp_dgrp_lines_by_sex[sex].push e
              end
            end
          end
        end
        @h_res[:dgrp_lines].each do |e|
          if (m = e.match(/^\s*\w*?_?0*(\d+)\s*$/))
            tmp_dgrp_lines.push ("DGRP_" + ("0" * (3-m[1].size)) + m[1])
          else
            tmp_dgrp_lines.push e
          end
        end
        
        
        
        @h_res[:warnings] ||= []
      #  missing_dgrp_lines = []
      #  tmp_dgrp_lines = [] 
      #  @h_res[:dgrp_lines].each do |e|
      #    if (m = e.match(/^\s*\w*?_?0*(\d+)\s*$/))
      #      tmp_dgrp_lines.push ("DGRP_" + ("0" * (3-m[1].size)) + m[1])
      #    else
      #      tmp_dgrp_lines.push e
      #    end
      #  end
        @found_dgrp_lines = tmp_dgrp_lines_by_sex#.select{|d| @h_dgrp_lines[d]}
        
        missing_dgrp_lines = tmp_dgrp_lines.select{|d| !@h_dgrp_lines[d]}
        if missing_dgrp_lines.size > 0
          @h_res[:warnings].push "DGRP lines are not found in DGRPool and will be ignored: #{missing_dgrp_lines.join(", ")}."
        end
      end
    else
      @h_res[:errors].push "File is missing"
    end

    @h_sex = {'F' => 'female', 'M' => 'male', 'NA' => 'unclassified'}
    @cur_sex = nil
    @list_sex = []
    @ordered_list_sex = []
    
    if @h_res[:errors].size == 0 and params[:compare] == '1' and params[:phenotype_name]

      @h_phenotypes = {}
      Phenotype.all.map{|p| @h_phenotypes[p.id] = p}
      col_i = [0, 1, @h_res[:header].index(params[:phenotype_name])]
      @content = []
      if col_i
        @content = @h_res[:matrix].map{|e| col_i.#reject{|i| !e or e[i] == '' or e[i] == 'NA'}.
                                         map{|i| (e and e[i] and (i < 2 or e[i] != 'NA')) ? e[i].gsub(/^\s*(-?\d+),(\d+)\s*$/, '\1.\2') : ''}.join("\t")}.join("\n")
#        @content = @h_res[:matrix].map{|e| col_i.map{|i| (e) ? ((e[i].match(/^\s*(-?\d+),(\d+)\s*$/)) ? e[i].gsub(/,/, '.') : e[i]) : ''}.join("\t")}.join("\n") 
      else
        @h_res[:errors].push("column not found for \"#{params[:phenotype_name]}\"")
      end
      t_header =  col_i.map{|i| @h_res[:header][i]} #.join("\t") + "\n"
      @h_correlation_res = Basic.compute_correlation(t_header, @content)
     # logger.debug "CMD:" + @h_correlation_res[:cmd]
     # logger.debug "OUTPUT_JSON:" + @h_correlation_res[:output_json].to_s
      if @h_correlation_res[:h_output]['which_sex']
        @list_sex = @h_correlation_res[:h_output]['which_sex']
        @ordered_list_sex = (0 .. @list_sex.size-1).sort{|a, b| @h_correlation_res[:res][@list_sex[b]].size <=> @h_correlation_res[:res][@list_sex[a]].size}.map{|i| @list_sex[i]}
        @cur_sex = @ordered_list_sex.first
      end
      ## write sums
      sum_file = @h_correlation_res[:output_dir] + 'dataset_sum.json'
      File.open(sum_file, 'w') do |fw|
        fw.write(h_sums[:all].to_json)
      end
      
      #md5 = Digest::SHA256.hexdigest @content
      #data_dir = Pathname.new(APP_CONFIG[:data_dir])
      #tmp_file = data_dir + "tmp" + "#{md5}.tmp"
      #output_dir =  data_dir + "tmp" + md5
      #export_mean_file = data_dir + 'export_mean.tsv'
      #@h_res[:header][0] = 'DGRP'
      #File.open(tmp_file, 'w') do |f|
      #  f.write(col_i.map{|i| @h_res[:header][i]}.join("\t") + "\n")
      #  f.write(@content)
      #end
      
      gwas_output_file = @h_correlation_res[:output_dir] + "gwas_output.json"
      gwas_output = {}
      if File.exist? gwas_output_file
        gwas_output = Basic.safe_parse_json(File.read(gwas_output_file), {})
      end

      render :partial => "all_correlation_results", :locals => {:h_correlation_res => @h_correlation_res, :gwas_output => gwas_output}
    else
      render :partial => "preparse_dataset"
    end
   
  end
  
  def pheno_correlation
    params[:only_integrated_studies] ||= '1'
    params[:data_source2] ||= 'mean'
    params[:data_source1] ||= 'mean'
  end

  def compute_correlation
    @log = []
    #    params[:only_integrated_studies] ||= '1'
    phenotypes = [Phenotype.where(:id => params[:phenotype_id1]).first, Phenotype.where(:id => params[:phenotype_id2]).first]
    @phenotypes = phenotypes.sort
    if phenotypes != @phenotypes
      tmp = params[:sex2]
      params[:sex2] = params[:sex1]
      params[:sex1] = tmp
      tmp = params[:data_source2]
      params[:data_source2] =  params[:data_source1]
      params[:data_source1] = tmp
    end

    phenotypes_sex = []
    phenotypes_sex = Basic.safe_parse_json("[" + (@phenotypes[0].sex_by_dgrp || "null") + "," + (@phenotypes[1].sex_by_dgrp || 'null') + "]", []) if @phenotypes.compact.size == 2
    @dgrp_line_ids=[]
    @common_dgrp_lines = []
    @common_studies = []
    @distinct_sex = [[], []]
    
    phenotypes_sex.each_index do |psi|
      if phenotypes_sex[psi]
        phenotypes_sex[psi].each_key do |dgrp|
          #   if phenotypes_sex[1][dgrp]
          @distinct_sex[psi] |= phenotypes_sex[psi][dgrp]
          #   end
        end
      end
    end
    @sex_comparisons = []
    
    if params[:sex1] == '' and params[:sex2] == ''
      common_sex = @distinct_sex[0] & @distinct_sex[1]
      if common_sex.size > 0
        common_sex.each do |s| 
          @sex_comparisons.push([s, s]) if s
        end
      else
         @sex_comparisons.push([@distinct_sex[0][0], @distinct_sex[1][0]])
      end
    else
      l = [((params[:sex1] != '') ? params[:sex1] : ((@distinct_sex[0].include? params[:sex2]) ? params[:sex2] : @distinct_sex[0].first)),
           ((params[:sex2] != '') ? params[:sex2] : ((@distinct_sex[1].include? params[:sex1]) ? params[:sex1] : @distinct_sex[1].first))]
      @sex_comparisons.push l if l.compact.size == 2
    end
    if @phenotypes.compact.size == 2
      @dgrp_line_ids = @phenotypes.map{|p| p.dgrp_line_studies.map{|e| e.dgrp_line_id}}
      @common_dgrp_lines = DgrpLine.where(:id => @dgrp_line_ids[0] & @dgrp_line_ids[1]).all.to_a
      @common_studies = Study.where(:id => DgrpLineStudy.joins(:phenotypes).where(:phenotypes => {:id => @phenotypes.map{|p| p.id}}, :dgrp_line_id => @common_dgrp_lines.map{|e| e.id}).all.map{|e| e.study_id}).all.to_a
    end

    axis = [:x, :y]
    list_sums = ["mean", "median", "variance", "std_dev", "std_err", "cv"]
    #    @h_studies = {}
    @all_data = []

    h_pheno = {}
    @common_studies.each do |s|
    #  s_attr = s.attributes
      h_pheno[s.id] = Basic.safe_parse_json(s.pheno_sum_json, {})
    end
    
    sum_i1 = list_sums.index(params[("data_source1").to_sym])
    sum_i2 = list_sums.index(params[("data_source2").to_sym])
    @sex_phenotypes = [[@phenotypes[0].id, sum_i1], [@phenotypes[1].id, sum_i2]]
    base_filename = @sex_phenotypes.map{|e| e[0].to_s + "_" + e[1].to_s}.join("_")
    filename = Pathname.new(APP_CONFIG[:data_dir]) + "tmp" + (base_filename + ".txt")
   # logger.debug(filename)
    output_file = Pathname.new(APP_CONFIG[:data_dir]) + "tmp" + (base_filename + ".json")
    corr_json = ""
    if File.exist? output_file
      corr_json = File.read(output_file)
    end
    if !File.exist? output_file or corr_json.match(/displayed_error/)
      ## create input file
      header = ["DGRP", "sex", "phenotype1", "phenotype2"]
      File.open(filename, 'w') do |fw|
        fw.write(header.join("\t") + "\n")
        @common_dgrp_lines.each do |dgrp|
          p1 = @phenotypes[0].id.to_s
          p2 = @phenotypes[1].id.to_s
          s_id1 = @phenotypes[0].study_id
          s_id2 = @phenotypes[1].study_id
          sex1 = h_pheno[s_id1][dgrp.name]["sex"]
          sex2 = h_pheno[s_id2][dgrp.name]["sex"]
          sex = sex1 | sex2
         # logger.debug("sex: " + sex.to_json)
          sex.each do |s|
            s_idx1 = sex1.index(s)
            s_idx2 = sex2.index(s)
#            sex: ["F","NA"]
#            ["F", ["F"], ["NA"], 0, nil]
#            ["NA", ["F"], ["NA"], nil, 0]

         #   logger.debug([s, sex1, sex2, s_idx1, s_idx2])
            if (s_idx1 and h_pheno[s_id1][dgrp.name][p1] and h_pheno[s_id1][dgrp.name][p1][s_idx1]) or
              (s_idx2 and h_pheno[s_id2][dgrp.name][p2] and h_pheno[s_id2][dgrp.name][p2][s_idx2])
            #  logger.debug([s_idx1, s_idx2,  ((s_idx1) ? h_pheno[s_id1][dgrp.name][p1][s_idx1] : ''),  ((s_idx2) ? h_pheno[s_id2][dgrp.name][p2][s_idx2] : '')])
              l = [dgrp.name, s,
                   ((s_idx1 and h_pheno[s_id1][dgrp.name][p1] and h_pheno[s_id1][dgrp.name][p1][s_idx1]) ?  h_pheno[s_id1][dgrp.name][p1][s_idx1][sum_i1] : ''),
                   ((s_idx2 and h_pheno[s_id2][dgrp.name][p2] and h_pheno[s_id2][dgrp.name][p2][s_idx2]) ? h_pheno[s_id2][dgrp.name][p2][s_idx2][sum_i2] : '')]
              fw.write(l.join("\t") + "\n")
            end
          end
        end
      end
      @cmd = "Rscript lib/correlation.R #{filename} > #{output_file}"
      `#{@cmd}`
      if File.exist? output_file
        corr_json = File.read(output_file)
      end
      
      #      File.delete filename
    end

    h_all_corr = Basic.safe_parse_json(corr_json, {})
    @h_corr = {}

    h_all_corr.each_key do |k|
      @h_corr[k] = h_all_corr[k] if h_all_corr[k]['common.notNA.dgrp'] > 0
    end
     # .select!{|e| e['common.notNA.dgrp'] > 0}
    
    @sex_comparisons.each do |sc|
    #  logger.debug("SEX_COMPARISON: #{sc}")
      @h_data = {:x => [], :y => [], :text => [],
                 mode: 'markers',
                 type: 'scatter',
                 marker: { size: 8, color: ((sc[0] == sc[1]) ? @h_sex_color[sc[0]] : 'grey') },
                 showlegend: false
                }
      #  @log = ''
      @common_studies.each do |s|
        #     @h_studies[s.id] = s
#        s_attr = s.attributes
        #      h_pheno = nil
        #      if @phenotype.is_global == true
        #        h_pheno = Basic.safe_parse_json(@study.pheno_json, {})['global']
        #    else
        #      @h_pheno = Basic.safe_parse_json(@study.pheno_json, {})['by_sample'][@phenotype.dataset_id.to_s]
        #    end
        #      ['mean', 'median'].each do |k|
        # phenotypes = []
        # phenotypes.push # ((params[:data_source1] == k) ? @phenotypes[0] : nil)
        # phenotypes.push #((params[:data_source2] == k) ? @phenotypes[1] : nil)
        #  @log += phenotypes.to_json
#        h_pheno = Basic.safe_parse_json(s_attr["pheno_sum_json"], {})
       
#        logger.debug h_pheno.to_json
        @common_dgrp_lines.each do |dgrp_line|
          if h_pheno[s.id][dgrp_line.name]
            sex = h_pheno[s.id][dgrp_line.name]["sex"]
            sex_indexes = [sex.index(sc[0]), sex.index(sc[1])]

            @phenotypes.sort{|a, b| a.id <=> b.id}.each_index do |j|
              p = @phenotypes[j]
              sum = params[("data_source#{j+1}").to_sym]
              sum_i = list_sums.index(sum)
              #     @log += h_pheno[dgrp_line.name].keys.to_json if h_pheno[dgrp_line.name]
              if p and h_pheno[s.id][dgrp_line.name][p.id.to_s]
                #               @log += p.to_json
                # h_pheno[dgrp_line.name][p.id.to_s].each_index do |i|
                #   sex_indexes = [sex.index(sc[0]), sex.index(sc[1])]
             #   logger.debug sex_indexes
                #    [sex.index(sc[0]), sex.index(sc[1])].compact.each do |i|
                if i = sex_indexes[j]
                  #                  @h_data ||= {:x => [], :y => [], :text => []}
                  @h_data[axis[j]].push (h_pheno[s.id][dgrp_line.name][p.id.to_s][i]) ? h_pheno[s.id][dgrp_line.name][p.id.to_s][i][sum_i] : nil 
                  @h_data[:text].push dgrp_line.name if j == 0
                  #    end
                end
              end
          end
          else
            @log.push "error: #{dgrp_line.name} not found"
          end
        end
        #     end
      end
      k = "#{sc[0]}_#{sc[1]}"
      min_x = @h_data[:x].compact.min
      max_x = @h_data[:x].compact.max

      trace = []
      
      if @h_corr[k]
        h_fake = {
          :x => [@h_data[:x].compact[0]],
          :y => [@h_data[:y].compact[0]],
          :name => "Pearson's r=#{@h_corr[k]['pearson_cor']}; Spearman's &#961;=#{@h_corr[k]['spearman_cor']}",
          mode: 'markers',
          type: 'scatter',
          :marker => {:color => "white"},
          showlegend: true
        }
        
        trace.push h_fake

      end
      
      trace.push @h_data
      
      if @h_corr[k]
        @h_line = {
          :x => [min_x, max_x],
          :y => [@h_corr[k]['lm_a'] * min_x + @h_corr[k]['lm_b'], @h_corr[k]['lm_a'] * max_x + @h_corr[k]['lm_b']],
          :name => "y = #{@h_corr[k]['lm_a']}*x + #{@h_corr[k]['lm_b']}; R<sup>2</sup>=#{@h_corr[k]['lm_r_squared']}",
          mode: 'lines',
          type: 'scatter',     
          :marker => {:color => "red"},
          showlegend: true
        }

        trace.push @h_line
        
      end
      
      @all_data.push trace
      
    end
    
    render :partial => "compute_correlation"
  end
  
  def gwas_analysis
  end
  
end
