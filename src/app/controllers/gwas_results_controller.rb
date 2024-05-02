class GwasResultsController < ApplicationController
  before_action :set_gwas_result, only: %i[ show edit update destroy ]

  def set_search_session
    [:search_type].each do |e|
      session[:gs_settings][e] = params[e] if params[e]
    end
  end

  
    def search
    session[:gs_settings][:free_text] ||= '' if !params[:free_text]
    session[:gs_settings][:page] ||= 1 if !params[:page]
    #   session[:gs_settings][:at_ids] ||= [1, 2, 3, 7] #(1 .. AssertionType.count()).to_a                                                                                                                              
    session[:gs_settings][:search_view_type] = 'list'

    #  @workspace = nil                                                                                                                                                                                                 
    #  if params[:workspace_key]                                                                                                                                                                                        
    #    @workspace = Workspace.where(:key => params[:workspace_key]).first                                                                                                                                             
    #  end                                                                                                                                                                                                              
    #   session[:as_settings][:at_ids] ||= (1 .. 7).to_a                                                                                                                                                                
    if params[:nolayout] == "1"
      render :layout => nil
    else
      render
    end
  end
    
    def core_search genes

      @h_var_types = {}
      VarType.all.map{|vt| @h_var_types[vt.id] = vt; @h_var_types[vt.name] = vt}
      
      @h_genes = {}
      Gene.where(:name => genes).all.map{|e| @h_genes[e.id] = e}
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
            :symbol => fa.symbol,
            :phenotype_name => pheno['phenotype_name'],
            :phenotype_id => pheno_key,
            :qualifiers => (0 .. pheno['qualifier_ids'].size-1).to_a.map{|i| [pheno['qualifier_ids'][i], pheno['qualifier_names'][i]]},
            :reference => pheno['reference']
          }
          @flybase_alleles.push el
        end
      end
    end
    
    def get_search

      genes = params[:q].split(/\s*[; ]\s*/)
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
   # session[:gs_settings][:at_ids] = params[:at_ids].split(",").map{|e| e.to_i} #if params[:at_ids]                                                                                                                    
    session[:gs_settings][:free_text] ||= ''
    session[:gs_settings][:free_text]=params[:free_text] if params[:free_text]
    session[:gs_settings][:search_type] ||= 'public'

    session[:gs_settings]["per_page".to_sym]||=50 #if !session[:settings][(prefix + "_per_page").to_sym] or session[:settings][(prefix + "_per_page").to_sym]== 0                                            \          

    session[:gs_settings]["page".to_sym]||=1
    ['per_page', 'page'].each do |e|
      session[:gs_settings][e.to_sym]=params[e.to_sym].to_i if params[e.to_sym] and params[e.to_sym].to_i != 0
    end
    free_text = session[:gs_settings][:free_text]

    free_text.strip!
    
    @h_impact = {
      'HIGH' => 'danger',
      'MODERATE' => 'warning',
      'LOW' => 'secondary',
      'MODIFIER' => 'info'
    }
        
    genes = free_text.split(/\s*[; ]\s*/)

    @snp_genes = []
    
    @h_counts = {
      :all => SnpGene.count
    }
    
    core_search(genes)
    render :partial => 'do_search' #'search_' + session[:settings][:search_view_type] + "_view"                                                      
    
  end
  
  # GET /gwas_results or /gwas_results.json
  def index
#    @gwas_results = GwasResult.all
  end

  # GET /gwas_results/1 or /gwas_results/1.json
  def show
  end

  # GET /gwas_results/new
  def new
    @gwas_result = GwasResult.new
  end

  # GET /gwas_results/1/edit
  def edit
  end

  # POST /gwas_results or /gwas_results.json
  def create
    @gwas_result = GwasResult.new(gwas_result_params)

    respond_to do |format|
      if @gwas_result.save
        format.html { redirect_to gwas_result_url(@gwas_result), notice: "Gwas result was successfully created." }
        format.json { render :show, status: :created, location: @gwas_result }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @gwas_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /gwas_results/1 or /gwas_results/1.json
  def update
    respond_to do |format|
      if @gwas_result.update(gwas_result_params)
        format.html { redirect_to gwas_result_url(@gwas_result), notice: "Gwas result was successfully updated." }
        format.json { render :show, status: :ok, location: @gwas_result }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @gwas_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gwas_results/1 or /gwas_results/1.json
  def destroy
    @gwas_result.destroy

    respond_to do |format|
      format.html { redirect_to gwas_results_url, notice: "Gwas result was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gwas_result
      @gwas_result = GwasResult.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def gwas_result_params
      params.fetch(:gwas_result, {})
    end
end
