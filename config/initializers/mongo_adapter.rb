module MongoAdapter
  class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
    def id
      @instance.id
    end
  end
 
  class DataAccessor < Sunspot::Adapters::DataAccessor
    def load(id)
      @clazz.find(id)
    end
    
    def load_all(ids)
      @clazz.find(ids)
    end
  end
end


Sunspot::Adapters::DataAccessor.register(MongoAdapter::DataAccessor, Thing)
Sunspot::Adapters::InstanceAdapter.register(MongoAdapter::InstanceAdapter, Thing)