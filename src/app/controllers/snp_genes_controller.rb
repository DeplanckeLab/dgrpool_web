class SnpGenesController < ApplicationController
  before_action :set_snp_gene, only: %i[ show edit update destroy ]

  # GET /snp_genes or /snp_genes.json
  def index
    @snp_genes = SnpGene.all
  end

  # GET /snp_genes/1 or /snp_genes/1.json
  def show
  end

  # GET /snp_genes/new
  def new
    @snp_gene = SnpGene.new
  end

  # GET /snp_genes/1/edit
  def edit
  end

  # POST /snp_genes or /snp_genes.json
  def create
    @snp_gene = SnpGene.new(snp_gene_params)

    respond_to do |format|
      if @snp_gene.save
        format.html { redirect_to snp_gene_url(@snp_gene), notice: "Snp gene was successfully created." }
        format.json { render :show, status: :created, location: @snp_gene }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @snp_gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /snp_genes/1 or /snp_genes/1.json
  def update
    respond_to do |format|
      if @snp_gene.update(snp_gene_params)
        format.html { redirect_to snp_gene_url(@snp_gene), notice: "Snp gene was successfully updated." }
        format.json { render :show, status: :ok, location: @snp_gene }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @snp_gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /snp_genes/1 or /snp_genes/1.json
  def destroy
    @snp_gene.destroy

    respond_to do |format|
      format.html { redirect_to snp_genes_url, notice: "Snp gene was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_snp_gene
      @snp_gene = SnpGene.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def snp_gene_params
      params.fetch(:snp_gene, {})
    end
end
