class FigureTypesController < ApplicationController
  before_action :set_figure_type, only: %i[ show edit update destroy ]

  # GET /figure_types or /figure_types.json
  def index
    @figure_types = FigureType.all
  end

  # GET /figure_types/1 or /figure_types/1.json
  def show
  end

  # GET /figure_types/new
  def new
    @figure_type = FigureType.new
  end

  # GET /figure_types/1/edit
  def edit
  end

  # POST /figure_types or /figure_types.json
  def create
    @figure_type = FigureType.new(figure_type_params)

    respond_to do |format|
      if @figure_type.save
        format.html { redirect_to figure_type_url(@figure_type), notice: "Figure type was successfully created." }
        format.json { render :show, status: :created, location: @figure_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @figure_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /figure_types/1 or /figure_types/1.json
  def update
    respond_to do |format|
      if @figure_type.update(figure_type_params)
        format.html { redirect_to figure_type_url(@figure_type), notice: "Figure type was successfully updated." }
        format.json { render :show, status: :ok, location: @figure_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @figure_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /figure_types/1 or /figure_types/1.json
  def destroy
    @figure_type.destroy

    respond_to do |format|
      format.html { redirect_to figure_types_url, notice: "Figure type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_figure_type
      @figure_type = FigureType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def figure_type_params
      params.fetch(:figure_type).permit(:name)
    end
end
