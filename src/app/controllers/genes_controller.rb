class GenesController < ApplicationController
  before_action :set_gene, only: %i[ show edit update destroy ]
  
  def autocomplete
    to_render = []
    
    q = (params[:q].rstrip != '') ? params[:q].rstrip.split(/[\, ]+/).last : ''
    
    query = Gene.search do
      fulltext q.gsub(/\$\{jndi\:/, '').gsub(/[+\-"\/]/) { |c| "\\" + c }
      field_list [:name, :full_name, :identifier, :synonyms]
      order_by :name_order, :asc
      paginate :page => 1, :per_page => 15
      adjust_solr_params do |params|
        params[:debugQuery] = 'true'
      end
    end

# Execute the search to get the raw Solr response
#    raw_response = search.raw
    
    # Extract debug information if available
    #   debug_info = raw_response['debug']
    
    # Logging the debug information
    #    logger.info("Solr Debug Info: #{debug_info.inspect}")
    
    genes = query.results
    
    query = Gene.search do
      fulltext q.gsub(/\$\{jndi\:/, '').gsub(/[+\-"\/]/) { |c| "\\" + c } + "*"
      field_list [:name, :full_name, :identifier, :synonyms]
      order_by :name_order, :asc
      paginate :page => 1, :per_page => 15
      adjust_solr_params do |params|
        params[:debugQuery] = 'true'
      end
    end
    
    genes |= query.results
    
    genes.each do |g|
      #      to_render.push({:id => g.id, :label => g.name})
      label = g.name
      label += "[#{g.full_name}]" if g.full_name and g.full_name != ''
      label += "[#{g.identifier}]" if g.identifier and g.identifier != ''
      to_render.push({:id => g.id, :label => label })
    end
    
    render :plain => to_render.to_json
    
  end
  
  
  def set_search_session
    [:search_type].each do |e|
      session[:gs_settings][e] = params[e] if params[e]
    end
  end
  
  
  def search
    session[:gs_settings][:free_text] ||= '' if !params[:free_text]
    session[:gs_settings][:page] ||= 1 if !params[:page]
    session[:gs_settings][:search_view_type] = 'list'
    if params[:nolayout] == "1"
      render :layout => nil
    else
      render
    end
  end
  
  def core_search gene_names
    
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
  
  def get_search
    
    genes = params[:q].gsub(/\[.+?\]/, "").split(/\s*[\, ]\s*/)
    logger.debug(genes.to_json)
    core_search(genes)
    data = []
    header = ["gene_name", "snp_id", "snp_type", "impact", "phenotype_id", "phenotype_name", "sex", "p_value", "transcript_annotation", "binding_side_annotation"]
    data.push(header)
    @gwas_results.each do |gr|
      vt = @h_var_types[@h_snp_genes[gr.snp_id].var_type_id]
      transcript_annot = ""
      binding_site_annot = ""
      if snp_info = @h_snp_info[@h_snps[gr.snp_id].identifier]
        transcript_annot = snp_info['transcript_annot'].keys.map{|k| snp_info['transcript_annot'][k]}.join("; ")
        binding_site_annot = snp_info['binding_site_annot'].keys.map{|k| snp_info['binding_site_annot'][k]}.join("; ")
      end
      l = [ @h_genes[@h_snp_genes[gr.snp_id].gene_id].name,
            @h_snps[gr.snp_id].identifier,
            vt.name,
	    vt.impact,
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
    session[:gs_settings][:search_view_type] = 'list'
    session[:gs_settings][:search_view_type] = params[:search_view_type] if params[:search_view_type] and params[:search_view_type] != ''
    session[:gs_settings][:free_text] ||= ''
    session[:gs_settings][:free_text]=params[:free_text] if params[:free_text]
    session[:gs_settings][:search_type] ||= 'public'
    
    session[:gs_settings]["per_page".to_sym]||=50 #if !session[:settings][(prefix + "_per_page").to_sym] or session[:settings][(prefix + "_per_page").to_sym]== 0
    session[:gs_settings]["page".to_sym]||=1
    ['per_page', 'page'].each do |e|
      session[:gs_settings][e.to_sym]=params[e.to_sym].to_i if params[e.to_sym] and params[e.to_sym].to_i != 0
    end
    free_text = session[:gs_settings][:free_text]
    
    free_text.strip!
    
    @h_units = {}
    Unit.all.map{|u| @h_units[u.id] = u}
    
    @h_impact = {
      'HIGH' => 'danger',
      'MODERATE' => 'warning',
      'LOW' => 'secondary',
      'MODIFIER' => 'info'
    }
    
    genes = free_text.gsub(/\[.+?\]/, "").split(/\s*[\, ]\s*/)
    
    @snp_genes = []
    
    @h_counts = {
      :all => SnpGene.count
    }
    
    core_search(genes)
    render :partial => 'do_search' #'search_' + session[:settings][:search_view_type] + "_view"                                                                                              
  end
  
  # GET /genes or /genes.json
  def index
     session[:gs_settings][:free_text] = params[:q]  if params[:q]
#    @genes = Gene.all
  end

  # GET /genes/1 or /genes/1.json
  def show
  end

  # GET /genes/new
  def new
    @gene = Gene.new
  end

  # GET /genes/1/edit
  def edit
  end

  # POST /genes or /genes.json
  def create
    @gene = Gene.new(gene_params)

    respond_to do |format|
      if @gene.save
        format.html { redirect_to gene_url(@gene), notice: "Gene was successfully created." }
        format.json { render :show, status: :created, location: @gene }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /genes/1 or /genes/1.json
  def update
    respond_to do |format|
      if @gene.update(gene_params)
        format.html { redirect_to gene_url(@gene), notice: "Gene was successfully updated." }
        format.json { render :show, status: :ok, location: @gene }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /genes/1 or /genes/1.json
  def destroy
    @gene.destroy

    respond_to do |format|
      format.html { redirect_to genes_url, notice: "Gene was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gene
      @gene = Gene.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def gene_params
      params.fetch(:gene, {})
    end
end
