class List
  include MongoMapper::Document
  include Sunspot::Rails::Searchable
  
  key :title, String, :required => true, :allow_blank => false
  key :description, String
  key :thing_ids, Array
  key :logic, Hash
  
  many :things, :in => :thing_ids
  one :user
  
  def contain?(thing)
    if live_things.include?(thing)
      return true
    else
      return false
    end
  end
  
  def live_things
    if logic.blank?
      things
    else
      Thing.all(logic)
    end
  end
end
