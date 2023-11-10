class VarTypesController < ApplicationController
  before_action :set_var_type, only: %i[ show edit update destroy ]

  # GET /var_types or /var_types.json
  def index
    @var_types = VarType.all
  end

  # GET /var_types/1 or /var_types/1.json
  def show
  end

  # GET /var_types/new
  def new
    @var_type = VarType.new
  end

  # GET /var_types/1/edit
  def edit
  end

  # POST /var_types or /var_types.json
  def create
    @var_type = VarType.new(var_type_params)

    respond_to do |format|
      if @var_type.save
        format.html { redirect_to var_type_url(@var_type), notice: "Var type was successfully created." }
        format.json { render :show, status: :created, location: @var_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @var_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /var_types/1 or /var_types/1.json
  def update
    respond_to do |format|
      if @var_type.update(var_type_params)
        format.html { redirect_to var_type_url(@var_type), notice: "Var type was successfully updated." }
        format.json { render :show, status: :ok, location: @var_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @var_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /var_types/1 or /var_types/1.json
  def destroy
    @var_type.destroy

    respond_to do |format|
      format.html { redirect_to var_types_url, notice: "Var type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_var_type
      @var_type = VarType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def var_type_params
      params.fetch(:var_type, {})
    end
end
