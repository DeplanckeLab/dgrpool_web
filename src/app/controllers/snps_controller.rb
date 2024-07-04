class SnpsController < ApplicationController
  before_action :set_snp, only: %i[ show edit update destroy get_phewas]
  
  def get_phewas
    
    @snp = Snp.where(:identifier => params[:snp_id]).first
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
    @snps = Snp.all
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
      if @snp.save
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
      if @snp.update(snp_params)
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
    @snp.destroy

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
