class Category
  include MongoMapper::EmbeddedDocument
  
  key :name, String, :required => true
  key :count, Integer
  key :description, String
  
  many :things
  many :sources
end
