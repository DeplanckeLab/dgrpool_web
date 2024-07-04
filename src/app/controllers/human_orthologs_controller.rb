class HumanOrthologsController < ApplicationController
  before_action :set_human_ortholog, only: %i[ show edit update destroy ]

  # GET /human_orthologs or /human_orthologs.json
  def index
    @human_orthologs = HumanOrtholog.all
  end

  # GET /human_orthologs/1 or /human_orthologs/1.json
  def show
  end

  # GET /human_orthologs/new
  def new
    @human_ortholog = HumanOrtholog.new
  end

  # GET /human_orthologs/1/edit
  def edit
  end

  # POST /human_orthologs or /human_orthologs.json
  def create
    @human_ortholog = HumanOrtholog.new(human_ortholog_params)

    respond_to do |format|
      if @human_ortholog.save
        format.html { redirect_to human_ortholog_url(@human_ortholog), notice: "Human ortholog was successfully created." }
        format.json { render :show, status: :created, location: @human_ortholog }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @human_ortholog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /human_orthologs/1 or /human_orthologs/1.json
  def update
    respond_to do |format|
      if @human_ortholog.update(human_ortholog_params)
        format.html { redirect_to human_ortholog_url(@human_ortholog), notice: "Human ortholog was successfully updated." }
        format.json { render :show, status: :ok, location: @human_ortholog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @human_ortholog.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /human_orthologs/1 or /human_orthologs/1.json
  def destroy
    @human_ortholog.destroy

    respond_to do |format|
      format.html { redirect_to human_orthologs_url, notice: "Human ortholog was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_human_ortholog
      @human_ortholog = HumanOrtholog.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def human_ortholog_params
      params.fetch(:human_ortholog, {})
    end
end
