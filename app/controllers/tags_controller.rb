class TagsController < ApplicationController
  
  def show
    @page_title = params[:id].capitalize
    @things = Thing.paginate(:page => page, :per_page => Setting.articles_per_page, :order => "created_at DESC", :tags => params[:id])
    respond_to do |format|
      format.html{
        render :template => "things/index"    
      }
    end
  end
  
end