class SnpsController < ApplicationController
  before_action :set_snp, only: %i[ show edit update destroy get_phewas]

  
  def set_search_session
    [:search_type].each do |e|
      session[:vs_settings][e] = params[e] if params[e]
    end
  end
  
  
  def search
    session[:vs_settings][:free_text] ||= '' if !params[:free_text]
    session[:vs_settings][:page] ||= 1 if !params[:page]
    session[:vs_settings][:search_view_type] = 'list'
    session[:vs_settings][:assembly] ||= params[:assembly]
    
    if params[:nolayout] == "1"
      render :layout => nil
    else
      render
    end
  end
  
  def core_search_old gene_names
    
    @nber_filters = 0
    [:filter_gene_name, :filter_by_pos, :filter_binding_site, :filter_involved_binding_site, :filter_variant_impact].each do |e|
      session[e] = params[e] if params[e]
      if session[e] != '' and session[e] != '0'
        @nber_filters+=1
      end
    end
    
    
    @h_var_types = {}
    VarType.all.map{|vt| @h_var_types[vt.id] = vt; @h_var_types[vt.name] = vt}
    
    @h_genes = {}
    
    genes = Gene.where(["identifier IN (?) or name IN (?) or full_name IN (?)", gene_names, gene_names, gene_names]).all
    h_terms = {}
    genes.map{|e| @h_genes[e.id] = e
      h_terms[e.identifier] = 1; h_terms[e.name] =1; h_terms[e.full_name] = 1
    }
    @not_found = gene_names - h_terms.keys
    
    
    @h_snp_genes = {}
    SnpGene.where(:gene_id => @h_genes.keys).all.map{|e| @h_snp_genes[e.snp_id] = e}
    @h_snps = {}
    snps = Snp.where(:id => @h_snp_genes.keys).all
    snps.map{|e| @h_snps[e.id] = e}
    @tmp_str = "{" + @h_snps.values.map{|snp|
      '"' + ((snp.identifier) ? snp.identifier : 'NA') + '":' + ((snp.annots_json) ? snp.annots_json : "null")
    }.join(",") + "}"
    @h_snp_info = Basic.safe_parse_json(@tmp_str, {})
    
    @gwas_results = GwasResult.where(:snp_id => @h_snps.keys).all
    @h_phenotypes = {}
    Phenotype.where(:id => @gwas_results.map{|e| e.phenotype_id}).all.map{|p| @h_phenotypes[p.id] = p}
    @h_studies = {}
    Study.where(:id => @h_phenotypes.values.map{|e| e.study_id}).all.map{|s| @h_studies[s.id] = s}
    
    @flybase_alleles = []
    flybase_alleles = FlybaseAllele.where(:gene_id => @h_genes.keys).all
    flybase_alleles.each do |fa|
      phenos = Basic.safe_parse_json(fa.phenotypes_json, {})
      phenos.each_key do |pheno_key|
        pheno = phenos[pheno_key]
        el = {
          :identifier => fa.identifier,
          :gene_id => fa.gene_id,
          :symbol => fa.symbol,
          :phenotype_name => pheno['phenotype_name'],
          :phenotype_id => pheno_key,
          :qualifiers => (0 .. pheno['qualifier_ids'].size-1).to_a.map{|i| [pheno['qualifier_ids'][i], pheno['qualifier_names'][i]]},
          :reference => pheno['reference']
        }
        @flybase_alleles.push el
      end
    end
    
    @oma_orthologs = OmaOrtholog.where(:gene_id => @h_genes.keys).all
    @h_organisms = {}
    Organism.where(:id => @oma_orthologs.map{|oo| oo.organism_id}).all.map{|e| @h_organisms[e.id] = e}
    @flybase_orthologs = HumanOrtholog.where(:gene_id => @h_genes.keys).all
  end

  def core_search free_text

    location_ranges = []
    snp_names = []
    free_text.gsub(/\[.+?\]/, "").split(/\s*[\, ]\s*/).map{|e|
      if e.match(/^\d?\w\:\d+\-\d+$/)
        location_ranges.push e
      else
        snp_names.push e
      end
    }
    

#:h_studies => @h_studies, :h_var_types => @h_var_types, :h_phenotypes => @h_phenotypes, :h_genes => @h_genes, :h_snps => @h_snps, :h_snp_info => @h_snp_info, :h_snp_genes => @h_snp_genes, :gwas_results => @gwas_results, 
    
    @not_found = []

    @h_var_types = {}
    VarType.all.map{|vt| @h_var_types[vt.id] = vt; @h_var_types[vt.name] = vt}
    
    
    @snps = []
    location_ranges.each do |location_range|
      t = location_range.split(":")
      t2 = t[1].split("-")
      if session[:vs_settings][:assembly] == 'dm3'
        @snps |= Snp.where("chr = '#{t[0]}' and pos <= #{t2[1]} and pos >= #{t2[0]}").all
      else
        @snps |= Snp.where("chr_dm6 = '#{t[0]}' and pos_dm6 <= #{t2[1]} and pos_dm6 >= #{t2[0]}").all
      end
    end

    if session[:vs_settings][:assembly] == 'dm3'
      @snps |= Snp.where(:identifier => snp_names).all
    else
      @snps |= Snp.where(:identifier_dm6 => snp_names).all
    end

    @h_snps = {}
    @h_snp_info ={}
    @gwas_results = []
    @h_snp_genes = {}
    @h_snp_genes2 = {}
    @h_genes = {}
    @h_phenotypes = {}
    @h_studies = {}
    
    if @snps.size <= 1000 or action_name == 'get_search'

      @snps.map{|e| @h_snps[e.id] = e}
      
      @tmp_str = "{" + @h_snps.values.map{|snp|
        '"' + ((snp.identifier) ? snp.identifier : 'NA') + '":' + ((snp.annots_json) ? snp.annots_json : "null")
      }.join(",") + "}"
      @h_snp_info = Basic.safe_parse_json(@tmp_str, {})
      
      SnpGene.where(:snp_id => @h_snps.keys).all.map{|e| @h_snp_genes[e.snp_id] = e; @h_snp_genes2[e.gene_id] = 1;}
      
      Gene.where(:id => @h_snp_genes2.keys).all.map{|e| @h_genes[e.id] = e} 
      
      @gwas_results = GwasResult.where(:snp_id => @h_snps.keys).all
      Phenotype.where(:id => @gwas_results.map{|e| e.phenotype_id}).all.map{|p| @h_phenotypes[p.id] = p}
      Study.where(:id => @h_phenotypes.values.map{|e| e.study_id}).all.map{|s| @h_studies[s.id] = s}
    end
    
  end
  
  def get_search
    
#    genes = params[:q].gsub(/\[.+?\]/, "").split(/\s*[\, ]\s*/)
    logger.debug(params[:q])    
    core_search(params[:q])
    data = []
    header = ["gene_name", "snp_id", "chr", "pos", "ref", "alt", "snp_type", "impact", "phenotype_id", "phenotype_name", "sex", "p_value", "transcript_annotation", "binding_side_annotation"]
    data.push(header)
    @gwas_results.each do |gr|
      sg = @h_snp_genes[gr.snp_id]
      vt = @h_var_types[sg.var_type_id] if sg
      transcript_annot = ""
      binding_site_annot = ""
      if snp_info = @h_snp_info[@h_snps[gr.snp_id].identifier]
        transcript_annot = snp_info['transcript_annot'].keys.map{|k| snp_info['transcript_annot'][k]}.join("; ")
        binding_site_annot = snp_info['binding_site_annot'].keys.map{|k| snp_info['binding_site_annot'][k]}.join("; ")
      end
      l = [ (sg) ? @h_genes[sg.gene_id].name : '-',
            @h_snps[gr.snp_id].identifier,
            @h_snps[gr.snp_id].chr,
            @h_snps[gr.snp_id].pos,
            @h_snps[gr.snp_id].ref,
            @h_snps[gr.snp_id].alt,
            (vt) ? vt.name : '-',
	    (vt) ? vt.impact : '-',
            (gr.phenotype_id) ? gr.phenotype_id : 'NA',
            (gr.phenotype_id) ? @h_phenotypes[gr.phenotype_id].name : 'NA',
            gr.sex,
            gr.p_val,
            transcript_annot,
	    binding_site_annot ]
      data.push l
    end
    render :plain => data.map{|l| l.join("\t")}.join("\n")
    
  end
  
  def do_search
    session[:vs_settings][:search_view_type] = 'list'
    session[:vs_settings][:search_view_type] = params[:search_view_type] if params[:search_view_type] and params[:search_view_type] != ''
    session[:vs_settings][:free_text] ||= ''
    session[:vs_settings][:free_text]=params[:free_text] if params[:free_text]
    session[:vs_settings][:assembly] = params[:assembly] if params[:assembly]
    session[:vs_settings][:search_type] ||= 'public'
    
    session[:vs_settings]["per_page".to_sym]||=50 #if !session[:settings][(prefix + "_per_page").to_sym] or session[:settings][(prefix + "_per_page").to_sym]== 0
    
    session[:vs_settings]["page".to_sym]||=1
    ['per_page', 'page'].each do |e|
      session[:vs_settings][e.to_sym]=params[e.to_sym].to_i if params[e.to_sym] and params[e.to_sym].to_i != 0
    end
    free_text = session[:vs_settings][:free_text]
    
    free_text.strip!
    
    @h_units = {}
    Unit.all.map{|u| @h_units[u.id] = u}
    
    @h_impact = {
      'HIGH' => 'danger',
      'MODERATE' => 'warning',
      'LOW' => 'secondary',
      'MODIFIER' => 'info'
    }

    @snp_genes = []

    @h_counts = {
      :all => Snp.count
    }
    
#    core_search(genes)
    core_search(free_text)#snp_names, location_ranges)
    

    render :partial => 'do_search' #'search_' + session[:settings][:search_view_type] + "_view"    
    
  end
  
  
  def get_phewas
    
#    @snp = Snp.where(:identifier => params[:snp_id]).first
   # @study = @phenotype.study
    @gwas_results = GwasResult.where(:snp_id => @snp.id).all
    @h_studies = {}
    Study.all.map{|s| @h_studies[s.id] = s}
    @h_phenotypes = {}
    @h_statuses = {}
    @h_units = {}
    Unit.all.map{|u| @h_units[u.id] = u}
    Status.all.map{|s| @h_statuses[s.id] =s }
    phenotypes = Phenotype.where(:id => @gwas_results.map{|e| e.phenotype_id}.uniq).all
    phenotypes.map{|e| @h_phenotypes[e.id] = e}
    
    render :partial => 'get_phewas'
    
  end
  
  # GET /snps or /snps.json
  def index
     session[:vs_settings][:free_text] = params[:q]  if params[:q]
#    @snps = Snp.all
  end

  # GET /snps/1 or /snps/1.json
  def show
  end

  # GET /snps/new
  def new
    @snp = Snp.new
  end

  # GET /snps/1/edit
  def edit
  end

  # POST /snps or /snps.json
  def create
    @snp = Snp.new(snp_params)

    respond_to do |format|
      if admin? and @snp.save
        format.html { redirect_to snp_url(@snp), notice: "Snp was successfully created." }
        format.json { render :show, status: :created, location: @snp }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @snp.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /snps/1 or /snps/1.json
  def update
    respond_to do |format|
      if admin? and @snp.update(snp_params)
        format.html { redirect_to snp_url(@snp), notice: "Snp was successfully updated." }
        format.json { render :show, status: :ok, location: @snp }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @snp.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /snps/1 or /snps/1.json
  def destroy
    @snp.destroy if admin?

    respond_to do |format|
      format.html { redirect_to snps_url, notice: "Snp was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_snp
      @snp = Snp.where(:id => params[:id]).first
      @snp = Snp.where(:identifier => params[:id]).first if !@snp
    end

    # Only allow a list of trusted parameters through.
    def snp_params
      params.fetch(:snp, {})
    end
end
