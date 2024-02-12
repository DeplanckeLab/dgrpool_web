class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show edit update destroy ]

  # GET /categories or /categories.json
  def index
    @categories = Category.all

    @h_nber_studies ={}
    @categories.map{|c| @h_nber_studies[c.id]= 0}
    Category.joins(:studies).select("categories.id as category_id, studies.id as study_id").all.map{|e|  @h_nber_studies[e.category_id] += 1} #.all Study.joins(:categories).all#.map{|e| e.e.category_id}
      #Study.joins("join categories_studies on (study_id = studies.id)").all #.map{|s| @h_nber_studies[s.category_id] += 1}

  end

  # GET /categories/1 or /categories/1.json
  def show
   @category = Category.find(params[:id])   
   @h_statuses = {}
   Status.all.map{|s|
     @h_statuses[s.id] = s
   }
     @h_users = {}
     User.all.map{|u| @h_users[u.id] = u}
  end

  # GET /categories/new
  def new
    if admin?
      @category = Category.new
    else
      render 'home/unauthorized'
    end
  end

  # GET /categories/1/edit
  def edit
    if !curator?
      redirect_to unauthorized_path
    end
  end

  # POST /categories or /categories.json
  def create
    
    @category = Category.new(category_params)
    @category.user_id = current_user.id 
    
    respond_to do |format|
      if curator? and  @category.save 
        format.html { redirect_to category_url(@category), notice: "Category was successfully created." }
        format.json { render :show, status: :created, location: @category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    respond_to do |format|    
      if curator? and @category.update(category_params)
        format.html { redirect_to category_url(@category), notice: "Category was successfully updated." }
        format.json { render :show, status: :ok, location: @category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy

    if admin?
      @category.destroy
    end
    respond_to do |format|
      format.html { redirect_to categories_url, notice: "Category was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def category_params
      params.fetch(:category).permit(:name, :description, :num)
    end
end
