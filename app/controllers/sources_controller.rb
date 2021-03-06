class SourcesController < ApplicationController
  before_filter :find_source, :only => [:show, :edit, :destroy]
  load_and_authorize_resource
  
  # GET /sources
  # GET /sources.xml
  def index
    @sources = Source.paginate(:page => page, :per_page => 10, :order => "created_at DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sources }
    end
  end

  # GET /sources/1
  # GET /sources/1.xml
  def show
    
    @things = @source.things.paginate(:page => page, :per_page => Setting.articles_per_page, :order => "created_at DESC")
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/new
  # GET /sources/new.xml
  def new
    @source = Source.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/1/edit
  def edit
    @source = Source.find(params[:id])
  end

  # POST /sources
  # POST /sources.xml
  def create
    unless params[:source][:categories].blank?
      params[:source][:categories] = params[:source][:categories].split(",").collect{|u| u.strip}.reject{|u| u.blank?}.uniq.collect{|p| Category.new(:name => p)}
    end
    unless params[:source][:feed_urls].blank?
      params[:source][:feed_urls] = params[:source][:feed_urls].split(",").collect{|u| u.strip}.reject{|u| u.blank?}.uniq
    end
    @source = Source.new(params[:source])

    respond_to do |format|
      if @source.save
        format.html { redirect_to(@source, :notice => 'Source was successfully created. We\'ll be doing an initial fetch of articles shortly.') }
        format.xml  { render :xml => @source, :status => :created, :location => @source }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sources/1
  # PUT /sources/1.xml
  def update
    @source = Source.find(params[:id])

    respond_to do |format|
      if @source.update_attributes(params[:source])
        format.html { redirect_to(@source, :notice => 'Source was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.xml
  def destroy
    @source = Source.find(params[:id])
    @source.destroy

    respond_to do |format|
      format.html { redirect_to(sources_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def find_source
    @source = Source.first(:slug => params[:id])
  end
end
