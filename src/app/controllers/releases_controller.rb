class ReleasesController < ApplicationController
  before_action :set_release, only: %i[ show edit update destroy file ]
  before_action :authorize_admin, only: %i[ new create edit update destroy ]

  # GET /releases or /releases.json
  def index
    @releases = Release.by_version
  end

  # GET /releases/1 or /releases/1.json
  def show
  end

  # GET /releases/new
  def new
    @release = Release.new
  end

  # GET /releases/1/edit
  def edit
  end

  # POST /releases or /releases.json
  def create
    @release = Release.new(release_params)

    respond_to do |format|
      if @release.save
        format.html { redirect_to release_url(@release), notice: "Release was successfully created." }
        format.json { render :show, status: :created, location: @release }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @release.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /releases/1 or /releases/1.json
  def update
    respond_to do |format|
      if @release.update(release_params)
        format.html { redirect_to release_url(@release), notice: "Release was successfully updated." }
        format.json { render :show, status: :ok, location: @release }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @release.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /releases/1 or /releases/1.json
  def destroy
    @release.destroy

    respond_to do |format|
      format.html { redirect_to releases_url, notice: "Release was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def file
    download = @release.downloads.find_by(:filename => params[:name])
    path = download && @release.file_path(download)
    if path && path.file?
      send_file path.to_s, :type => params[:content_type] || "text",
                :x_sendfile => true, :buffer_size => 512,
                :disposition => "attachment; filename=" + download.filename
    else
      render :plain => "This file doesn't exist.", :status => :not_found
    end
  end

  private
    def set_release
      @release = Release.find(params[:id])
    end

    def release_params
      params.require(:release).permit(:name, :description, :url, :gwas_command, :release_date, :download_ids => [])
    end
end
