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
  
  many :things
  many :categories
end
