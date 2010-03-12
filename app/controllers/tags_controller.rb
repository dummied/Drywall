class TagsController < ApplicationController
  
  def show
    @things = Thing.paginate(:page => params[:page] || 1, :per_page => 30, :order => "created_at DESC", :tags => params[:id])
    render :template => "things/index"    
  end
  
end