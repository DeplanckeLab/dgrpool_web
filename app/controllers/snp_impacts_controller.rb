class SnpImpactsController < ApplicationController
  before_action :set_snp_impact, only: %i[ show edit update destroy ]

  # GET /snp_impacts or /snp_impacts.json
  def index
    @snp_impacts = SnpImpact.all
  end

  # GET /snp_impacts/1 or /snp_impacts/1.json
  def show
  end

  # GET /snp_impacts/new
  def new
    @snp_impact = SnpImpact.new
  end

  # GET /snp_impacts/1/edit
  def edit
  end

  # POST /snp_impacts or /snp_impacts.json
  def create
    @snp_impact = SnpImpact.new(snp_impact_params)

    respond_to do |format|
      if @snp_impact.save
        format.html { redirect_to snp_impact_url(@snp_impact), notice: "Snp impact was successfully created." }
        format.json { render :show, status: :created, location: @snp_impact }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @snp_impact.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /snp_impacts/1 or /snp_impacts/1.json
  def update
    respond_to do |format|
      if @snp_impact.update(snp_impact_params)
        format.html { redirect_to snp_impact_url(@snp_impact), notice: "Snp impact was successfully updated." }
        format.json { render :show, status: :ok, location: @snp_impact }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @snp_impact.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /snp_impacts/1 or /snp_impacts/1.json
  def destroy
    @snp_impact.destroy

    respond_to do |format|
      format.html { redirect_to snp_impacts_url, notice: "Snp impact was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_snp_impact
      @snp_impact = SnpImpact.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def snp_impact_params
      params.fetch(:snp_impact, {})
    end
end
