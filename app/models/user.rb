class User
  include MongoMapper::Document
  before_save :rolify
  
  ROLES = %w[admin author]
  
  devise :authenticatable, :recoverable, :rememberable, :trackable, :validatable, :registerable
  
  key :role, String
  
  many :things
  many :lists, :dependent => :destroy
  
  def admin?
    role && role == "admin"
  end
  
  def author?
    role && role == "author"
  end  
  
  def rolify
    if (Setting.find_by_name("run_once").value == true) && User.count == 0
      role = "admin"
      Setting.find_by_name("run_once").update_attributes!(:value => false)
      File.open("#{Rails.root}/config/startup_complete", 'w') {|f| f.write(Time.now.to_s) } 
    elsif role.blank? || (current_user && !current_user.admin?)
      role = "author"
    end
  end
  
end