class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :run_once unless File.exists?("#{Rails.root}/config/startup_complete")  
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to root_url
  end
  
  private
  
  def run_once
    if (params[:controller] != "devise/registrations") && (Setting.find_by_name("run_once").value == true)
      redirect_to new_user_registration_path
    end
  end
  
  def page
    params[:page] || 1
  end
end
