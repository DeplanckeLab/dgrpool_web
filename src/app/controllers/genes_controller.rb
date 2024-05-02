class GenesController < ApplicationController
  before_action :set_gene, only: %i[ show edit update destroy ]

  def autocomplete
    to_render = []
    
    q = params[:q].strip.split(/ +/).last
    
    query = Gene.search do
      fulltext q.gsub(/\$\{jndi\:/, '').gsub(/[+\-"\/]/) { |c| "\\" + c } + "*"
      field_list [:name]
      order_by :name_order, :asc
      paginate :page => 1, :per_page => 15
    end

    genes = query.results
    genes.each do |g|
      to_render.push({:id => g.id, :label => g.name})
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
    
    words = free_text.split(/\s*[; ]\s*/)
    
  #  @h_assertion_types = {}
  #  AssertionType.all.map{|at| @h_assertion_types[at.id] = at}
    
  #  @h_assessment_types = {}
  #  AssessmentType.all.map{|at| @h_assessment_types[at.id] = at}
    
  #  @assertions = []
    @snp_genes = []
   # @h_journals = {}
   # Journal.all.map{|j| @h_journals[j.id] = j}
    
   # conds = ["content != '' and assertion_type_id in (?) and assertions.obsolete=false and articles.obsolete=false", session[:as_settings][:at_ids]]

    
  #  workspace_val = nil
  #  @workspace = nil
  #  if params[:workspace_key]
  #    @workspace = Workspace.where(:key => params[:workspace_key]).first
  #    workspace_cond = " and workspace_id = ?"
  #    workspace_val = @workspace.id
  #    conds[0] += workspace_cond
  #    conds.push workspace_val
  #  end
    @h_counts = {
      :all => SnpGene.count
    }
    
    #     constraint_at_ids = (params[:assessment_type_id] == '') ? (1 .. AssertionType.count).to_a : AssertionType.where(:name => ['major_claim', 'minor_claim', 'method', 'evidence']).all.map{|e| e.id}    
    
    @query = SnpGene.search do
      fulltext words.join(" ").gsub(/\$\{jndi\:/, '').gsub(/[\{\}\$\:\\]/, '')
      #order_by(:updated_at, :desc)                                                                                                                                                                           
  #    without(:content, nil)
  #    with(:workspace_id, workspace_val) if workspace_val
  #    with(:assertion_type_id, (session[:as_settings][:at_ids].size > 0) ? session[:as_settings][:at_ids] : [-1]) # & constraint_at_ids)                                                                      
  #    with(:assessment_type_id, (params[:assessment_type_id] == '5') ? [params[:assessment_type_id], ''] : params[:assessment_type_id])  if params[:assessment_type_id] != ''
  #    with(:obsolete, false)
  #    with(:obsolete_article, false)
      paginate :page => session[:gs_settings][:page], :per_page => session[:gs_settings][:per_page]
    end
    
    @snp_genes= @query.results

    @h_genes = {}
    Gene.where(:id => @snp_genes.map{|e| e.gene_id}).all.map{|e| @h_genes[e.id] = e}
    @h_snps = {}
    Snp.where(:id => @snp_genes.map{|e| e.snp_id}).all.map{|e| @h_snps[e.id] = e}

    @gwas_results = GwasResult.where(:snp_id => @h_snps.keys).all
    
    render :partial => 'do_search' #'search_' + session[:settings][:search_view_type] + "_view"                                                                                                               
    
  end
  
  # GET /genes or /genes.json
  def index
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
