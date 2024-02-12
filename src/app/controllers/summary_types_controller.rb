class SummaryTypesController < ApplicationController
  before_action :set_summary_type, only: %i[ show edit update destroy ]

  # GET /summary_types or /summary_types.json
  def index
    @summary_types = SummaryType.all
  end

  # GET /summary_types/1 or /summary_types/1.json
  def show
  end

  # GET /summary_types/new
  def new
    @summary_type = SummaryType.new
  end

  # GET /summary_types/1/edit
  def edit
  end

  # POST /summary_types or /summary_types.json
  def create
    @summary_type = SummaryType.new(summary_type_params)

    respond_to do |format|
      if @summary_type.save
        format.html { redirect_to summary_type_url(@summary_type), notice: "Summary type was successfully created." }
        format.json { render :show, status: :created, location: @summary_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @summary_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /summary_types/1 or /summary_types/1.json
  def update
    respond_to do |format|
      if @summary_type.update(summary_type_params)
        format.html { redirect_to summary_type_url(@summary_type), notice: "Summary type was successfully updated." }
        format.json { render :show, status: :ok, location: @summary_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @summary_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /summary_types/1 or /summary_types/1.json
  def destroy
    @summary_type.destroy

    respond_to do |format|
      format.html { redirect_to summary_types_url, notice: "Summary type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_summary_type
      @summary_type = SummaryType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def summary_type_params
      params.fetch(:summary_type).permit(:name)
    end
end
