class CategoriesController < ApplicationController
  
  # GET /categories
  # GET /categories.xml
  def index
    @categories = Category.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  # GET /categories/1
  # GET /categories/1.xml
  def show
    @page_title = params[:id].capitalize
    @things = Thing.paginate(:page => page, :per_page => Setting.articles_per_page, :order => "created_at DESC", 'categories.name' => params[:id])
    @sources = Source.all('categories.name' => params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

end
