class DgrpStatusesController < ApplicationController
  before_action :set_dgrp_status, only: %i[ show edit update destroy ]
  before_action :authorize_admin
  # GET /dgrp_statuses or /dgrp_statuses.json
  def index
    @dgrp_statuses = DgrpStatus.all
  end

  # GET /dgrp_statuses/1 or /dgrp_statuses/1.json
  def show
  end

  # GET /dgrp_statuses/new
  def new
    @dgrp_status = DgrpStatus.new
  end

  # GET /dgrp_statuses/1/edit
  def edit
  end

  # POST /dgrp_statuses or /dgrp_statuses.json
  def create
    @dgrp_status = DgrpStatus.new(dgrp_status_params)

    respond_to do |format|
      if @dgrp_status.save
        format.html { redirect_to dgrp_status_url(@dgrp_status), notice: "Dgrp status was successfully created." }
        format.json { render :show, status: :created, location: @dgrp_status }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dgrp_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dgrp_statuses/1 or /dgrp_statuses/1.json
  def update
    respond_to do |format|
      if @dgrp_status.update(dgrp_status_params)
        format.html { redirect_to dgrp_status_url(@dgrp_status), notice: "Dgrp status was successfully updated." }
        format.json { render :show, status: :ok, location: @dgrp_status }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dgrp_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dgrp_statuses/1 or /dgrp_statuses/1.json
  def destroy
    @dgrp_status.destroy

    respond_to do |format|
      format.html { redirect_to dgrp_statuses_url, notice: "Dgrp status was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dgrp_status
      @dgrp_status = DgrpStatus.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dgrp_status_params
      params.fetch(:dgrp_status).permit(:name, :css_class, :label, :description, :url_mask)
    end
end
