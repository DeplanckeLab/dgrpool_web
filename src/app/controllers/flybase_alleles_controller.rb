class FlybaseAllelesController < ApplicationController
  before_action :set_flybase_allele, only: %i[ show edit update destroy ]

  # GET /flybase_alleles or /flybase_alleles.json
  def index
    @flybase_alleles = FlybaseAllele.all
  end

  # GET /flybase_alleles/1 or /flybase_alleles/1.json
  def show
  end

  # GET /flybase_alleles/new
  def new
    @flybase_allele = FlybaseAllele.new
  end

  # GET /flybase_alleles/1/edit
  def edit
  end

  # POST /flybase_alleles or /flybase_alleles.json
  def create
    @flybase_allele = FlybaseAllele.new(flybase_allele_params)

    respond_to do |format|
      if @flybase_allele.save
        format.html { redirect_to flybase_allele_url(@flybase_allele), notice: "Flybase allele was successfully created." }
        format.json { render :show, status: :created, location: @flybase_allele }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @flybase_allele.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /flybase_alleles/1 or /flybase_alleles/1.json
  def update
    respond_to do |format|
      if @flybase_allele.update(flybase_allele_params)
        format.html { redirect_to flybase_allele_url(@flybase_allele), notice: "Flybase allele was successfully updated." }
        format.json { render :show, status: :ok, location: @flybase_allele }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @flybase_allele.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /flybase_alleles/1 or /flybase_alleles/1.json
  def destroy
    @flybase_allele.destroy

    respond_to do |format|
      format.html { redirect_to flybase_alleles_url, notice: "Flybase allele was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_flybase_allele
      @flybase_allele = FlybaseAllele.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def flybase_allele_params
      params.fetch(:flybase_allele, {})
    end
end
