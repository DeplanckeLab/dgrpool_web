class DgrpLinesController < ApplicationController
  before_action :set_dgrp_line, only: %i[ show edit update destroy ]

  # GET /dgrp_lines or /dgrp_lines.json
  def index
    @dgrp_lines = DgrpLine.all

    @h_dgrp_statuses = {}
    DgrpStatus.all.map{|a| @h_dgrp_statuses[a.id] = a}
    @nber_studies = Study.where(:status_id => [2, 4]).count
#    @h_studies = {}
#    Study.all.map{|s| @h_studies[s.id] = s}
#    @h_dgrp_studies ={}
#    @h_dgrp_line_studies = {}
#    DgrpLineStudy.all.map{|e|
#      @h_dgrp_studies[e.dgrp_line_id] ||= [];
#      @h_dgrp_studies[e.dgrp_line_id].push e.study_id
#      @h_dgrp_line_studies[e.id] = e
#    }

#    @h_phenotypes = {}
#    @h_phenotypes_by_dgrp_line = {}
#    Phenotype.all.map{|p|
#      @h_phenotypes[p.id] = p
#     }
#    Phenotype.joins(:dgrp_line_studies).select("dgrp_line_studies.id as dgrp_line_study_id, phenotypes.id as phenotype_id").all.map{|e|
#      @h_phenotypes_by_dgrp_line[@h_dgrp_line_studies[e[:dgrp_line_study_id]].dgrp_line_id] ||= []
#      @h_phenotypes_by_dgrp_line[@h_dgrp_line_studies[e[:dgrp_line_study_id]].dgrp_line_id].push e[:phenotype_id]
#     
#   }

    

    
  end

  # GET /dgrp_lines/1 or /dgrp_lines/1.json
  def show
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    @h_cats = {}
    Category.all.map{|c| @h_cats[c.id] = c}
    @h_dgrp_statuses = {}
    DgrpStatus.all.map{|a| @h_dgrp_statuses[a.id] = a}

    @h_users = {}
    User.all.map{|u| @h_users[u.id]=u }
    
    @dgrp_line_studies = @dgrp_line.dgrp_line_studies
     @h_cats_by_study = {}
     @dgrp_line_studies.map{|s|
       @h_cats_by_study[s.study_id]= []
     }
     Category.joins("join categories_studies on (categories_studies.category_id = categories.id)").select("categories.id as category_id, categories_studies.study_id as study_id").where(:categories_studies => {:study_id => @h_cats_by_study.keys}).map{|e| @h_cats_by_study[e.study_id]||=[]; @h_cats_by_study[e.study_id].push(e.category_id)}

     h_phenotype_ids = {}
     Phenotype.joins(:dgrp_line_studies).select("dgrp_line_studies.id as dgrp_line_study_id, phenotypes.id as phenotype_id").where(:dgrp_line_studies => {:id => @dgrp_line_studies.map{|e| e.id}}).all.map{|e|
       h_phenotype_ids[e[:phenotype_id]] =1
     }
     
     @phenotypes = (curator?) ? Phenotype.where(:id => h_phenotype_ids.keys).all : Phenotype.where(:id => h_phenotype_ids.keys, :obsolete => false).all
     
  end
  
  # GET /dgrp_lines/new
  def new
    @dgrp_line = DgrpLine.new
  end

  # GET /dgrp_lines/1/edit
  def edit
    if !curator?
      redirect_to unauthorized_path
    end
  end

  # POST /dgrp_lines or /dgrp_lines.json
  def create
    @dgrp_line = DgrpLine.new(dgrp_line_params)

    respond_to do |format|
      if curator? and @dgrp_line.save
        format.html { redirect_to dgrp_line_url(@dgrp_line), notice: "Dgrp line was successfully created." }
        format.json { render :show, status: :created, location: @dgrp_line }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dgrp_line.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dgrp_lines/1 or /dgrp_lines/1.json
  def update
    respond_to do |format|
      if curator? and @dgrp_line.update(dgrp_line_params)
        format.html { redirect_to dgrp_line_url(@dgrp_line), notice: "Dgrp line was successfully updated." }
        format.json { render :show, status: :ok, location: @dgrp_line }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dgrp_line.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dgrp_lines/1 or /dgrp_lines/1.json
  def destroy
    if admin?
      @dgrp_line.dgrp_line_studies.destroy_all
      @dgrp_line.phenotypes.delete_all
      @dgrp_line.destroy
    end

    respond_to do |format|
      format.html { redirect_to dgrp_lines_url, notice: "Dgrp line was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dgrp_line
      @dgrp_line = DgrpLine.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dgrp_line_params
      params.fetch(:dgrp_line, {})
    end
end
