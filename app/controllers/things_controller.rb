class ThingsController < ApplicationController
  load_and_authorize_resource
  
  # GET /things
  # GET /things.xml
  def index
    @things = Thing.paginate(:page => page, :per_page => Setting.articles_per_page, :order => "created_at DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @things }
    end
  end

  # GET /things/1/edit
  def edit
    @thing = Thing.find(params[:id])
  end

  # POST /things
  # POST /things.xml
  def create
    @thing = Thing.new(params[:thing])

    respond_to do |format|
      if @thing.save
        format.html { redirect_to(@thing, :notice => 'Thing was successfully created.') }
        format.xml  { render :xml => @thing, :status => :created, :location => @thing }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @thing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /things/1
  # PUT /things/1.xml
  def update
    @thing = Thing.find(params[:id])

    respond_to do |format|
      if @thing.update_attributes(params[:thing])
        format.html { redirect_to(@thing, :notice => 'Thing was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @thing.errors, :status => :unprocessable_entity }
      end
    end
  end

end
