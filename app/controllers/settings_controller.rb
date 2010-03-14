class SettingsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @settings = Setting.all(:name.ne => "run_once", :order => "created_at DESC")
  end
  
  def update
    @setting = Setting.find(params[:id])
    @setting.update_attributes(params[:setting])
    flash[:notice] = "Setting has been updated"
    redirect_to settings_path
  end
  
  
end