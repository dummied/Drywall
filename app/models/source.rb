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
  
  after_create :delayed_fetch
  
  def last_thing
    things.first(:order => "created_at DESC")
  end
  
  def to_param
    slug
  end
  
  def fetch
    feed_urls.each do |f|
      Fetch.single(f, self)
    end
  end
  
  
  def delayed_fetch
    self.send_later(:fetch)
  end
  
end
