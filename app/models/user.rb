class User
  include MongoMapper::Document
  before_save :rolify
  
  ROLES = %w[admin author]
  
  devise :authenticatable, :recoverable, :rememberable, :trackable, :validatable, :registerable
  
  key :role, String
  
  many :things
  many :lists
  
  def admin?
    role && role == "admin"
  end
  
  def author?
    role && role == "author"
  end  
  
  def rolify
    if role.blank?
      role = "author"
    end
  end
  
end