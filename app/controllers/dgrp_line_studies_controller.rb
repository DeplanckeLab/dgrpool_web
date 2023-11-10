class DgrpLineStudiesController < ApplicationController
  before_action :set_dgrp_line_study, only: %i[ show edit update destroy ]

  # GET /dgrp_line_studies or /dgrp_line_studies.json
  def index
    @dgrp_line_studies = DgrpLineStudy.all
  end

  # GET /dgrp_line_studies/1 or /dgrp_line_studies/1.json
  def show
  end

  # GET /dgrp_line_studies/new
  def new
    @dgrp_line_study = DgrpLineStudy.new
  end

  # GET /dgrp_line_studies/1/edit
  def edit
  end

  # POST /dgrp_line_studies or /dgrp_line_studies.json
  def create
    @dgrp_line_study = DgrpLineStudy.new(dgrp_line_study_params)

    respond_to do |format|
      if @dgrp_line_study.save
        format.html { redirect_to dgrp_line_study_url(@dgrp_line_study), notice: "Dgrp line study was successfully created." }
        format.json { render :show, status: :created, location: @dgrp_line_study }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dgrp_line_study.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dgrp_line_studies/1 or /dgrp_line_studies/1.json
  def update
    respond_to do |format|
      if @dgrp_line_study.update(dgrp_line_study_params)
        format.html { redirect_to dgrp_line_study_url(@dgrp_line_study), notice: "Dgrp line study was successfully updated." }
        format.json { render :show, status: :ok, location: @dgrp_line_study }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dgrp_line_study.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dgrp_line_studies/1 or /dgrp_line_studies/1.json
  def destroy
    @dgrp_line_study.destroy

    respond_to do |format|
      format.html { redirect_to dgrp_line_studies_url, notice: "Dgrp line study was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dgrp_line_study
      @dgrp_line_study = DgrpLineStudy.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dgrp_line_study_params
      #      params.fetch(:dgrp_line_study, {})
      params.fetch(:dgrp_line_study).permit(:obsolete)
    end
end
