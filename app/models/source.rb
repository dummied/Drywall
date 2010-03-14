class Source
  include MongoMapper::Document
  
  key :feed_urls, Array
  key :count, Integer
  key :home_url, String
  key :name, String
  key :slug, String
  key :description, String
  key :tags, Array
  timestamps!
  
  many :things, :dependent => :destroy
  many :categories
  
  
  def last_thing
    things.first(:order => "created_at DESC")
  end
  
  def to_param
    slug
  end
  
end
