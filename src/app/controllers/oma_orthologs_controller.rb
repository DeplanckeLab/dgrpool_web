class OmaOrthologsController < ApplicationController
  before_action :set_oma_ortholog, only: %i[ show edit update destroy ]

  # GET /oma_orthologs or /oma_orthologs.json
  def index
    @oma_orthologs = OmaOrtholog.all
  end

  # GET /oma_orthologs/1 or /oma_orthologs/1.json
  def show
  end

  # GET /oma_orthologs/new
  def new
    @oma_ortholog = OmaOrtholog.new
  end

  # GET /oma_orthologs/1/edit
  def edit
  end

  # POST /oma_orthologs or /oma_orthologs.json
  def create
    @oma_ortholog = OmaOrtholog.new(oma_ortholog_params)

    respond_to do |format|
      if @oma_ortholog.save
        format.html { redirect_to oma_ortholog_url(@oma_ortholog), notice: "Oma ortholog was successfully created." }
        format.json { render :show, status: :created, location: @oma_ortholog }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @oma_ortholog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /oma_orthologs/1 or /oma_orthologs/1.json
  def update
    respond_to do |format|
      if @oma_ortholog.update(oma_ortholog_params)
        format.html { redirect_to oma_ortholog_url(@oma_ortholog), notice: "Oma ortholog was successfully updated." }
        format.json { render :show, status: :ok, location: @oma_ortholog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @oma_ortholog.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /oma_orthologs/1 or /oma_orthologs/1.json
  def destroy
    @oma_ortholog.destroy

    respond_to do |format|
      format.html { redirect_to oma_orthologs_url, notice: "Oma ortholog was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_oma_ortholog
      @oma_ortholog = OmaOrtholog.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def oma_ortholog_params
      params.fetch(:oma_ortholog, {})
    end
end
