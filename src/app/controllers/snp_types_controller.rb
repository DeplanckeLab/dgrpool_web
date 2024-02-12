class SnpTypesController < ApplicationController
  before_action :set_snp_type, only: %i[ show edit update destroy ]

  # GET /snp_types or /snp_types.json
  def index
    @snp_types = SnpType.all
  end

  # GET /snp_types/1 or /snp_types/1.json
  def show
  end

  # GET /snp_types/new
  def new
    @snp_type = SnpType.new
  end

  # GET /snp_types/1/edit
  def edit
  end

  # POST /snp_types or /snp_types.json
  def create
    @snp_type = SnpType.new(snp_type_params)

    respond_to do |format|
      if @snp_type.save
        format.html { redirect_to snp_type_url(@snp_type), notice: "Snp type was successfully created." }
        format.json { render :show, status: :created, location: @snp_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @snp_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /snp_types/1 or /snp_types/1.json
  def update
    respond_to do |format|
      if @snp_type.update(snp_type_params)
        format.html { redirect_to snp_type_url(@snp_type), notice: "Snp type was successfully updated." }
        format.json { render :show, status: :ok, location: @snp_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @snp_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /snp_types/1 or /snp_types/1.json
  def destroy
    @snp_type.destroy

    respond_to do |format|
      format.html { redirect_to snp_types_url, notice: "Snp type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_snp_type
      @snp_type = SnpType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def snp_type_params
      params.fetch(:snp_type, {})
    end
end
