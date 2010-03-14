class Setting
  include MongoMapper::Document
  
  def self.method_missing(method, *args) 
    if setting = self.first(:name => method.to_s)
      return setting.value
    else
      super(method, *args)
    end
  end
  
end