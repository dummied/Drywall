%w(query_facet field_facet date_facet facet_row hit
   highlight).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

module Sunspot
  # 
  # This class encapsulates the results of a Solr search. It provides access
  # to search results, total result count, facets, and pagination information.
  # Instances of Search are returned by the Sunspot.search and
  # Sunspot.new_search methods.
  #
  class Search
    attr_reader :query #:nodoc:
    # 
    # Retrieve all facet objects defined for this search, in order they were
    # defined. To retrieve an individual facet by name, use #facet()
    #
    attr_reader :facets

    def initialize(connection, setup, query, configuration) #:nodoc:
      @connection, @setup, @query = connection, setup, query
      @query.paginate(1, configuration.pagination.default_per_page)
      @facets = []
      @facets_by_name = {}
    end

    #
    # Execute the search on the Solr instance and store the results. If you
    # use Sunspot#search() to construct your searches, there is no need to call
    # this method as it has already been called. If you use
    # Sunspot#new_search(), you will need to call this method after building the
    # query.
    #
    def execute
      reset
      params = @query.to_params
      @solr_result = @connection.select(params)
      self
    end
    alias_method :execute!, :execute #:nodoc: deprecated

    # 
    # Get the collection of results as instantiated objects. If WillPaginate is
    # available, the results will be a WillPaginate::Collection instance; if
    # not, it will be a vanilla Array.
    #
    # If not all of the results referenced by the Solr hits actually exist in
    # the data store, Sunspot will only return the results that do exist.
    #
    # ==== Returns
    #
    # WillPaginate::Collection or Array:: Instantiated result objects
    #
    def results
      @results ||= maybe_will_paginate(verified_hits.map { |hit| hit.instance })
    end

    # 
    # Access raw Solr result information. Returns a collection of Hit objects
    # that contain the class name, primary key, keyword relevance score (if
    # applicable), and any stored fields.
    #
    # ==== Options (options)
    #
    # :verify::
    #   Only return hits that reference objects that actually exist in the data
    #   store. This causes results to be eager-loaded from the data store,
    #   unlike the normal behavior of this method, which only loads the
    #   referenced results when Hit#result is first called.
    #
    # ==== Returns
    #
    # Array:: Ordered collection of Hit objects
    #
    def hits(options = {})
      if options[:verify]
        verified_hits
      else
        @hits ||=
          maybe_will_paginate(
            solr_response['docs'].map do |doc|
              Hit.new(doc, highlights_for(doc), distance_for(doc), self)
            end
          )
      end
    end
    alias_method :raw_results, :hits

    #
    # Convenience method to iterate over hit and result objects. Block is
    # yielded a Sunspot::Server::Hit instance and a Sunspot::Server::Result
    # instance.
    #
    # Note that this method iterates over verified hits (see #hits method
    # for more information).
    #
    def each_hit_with_result
      verified_hits.each do |hit|
        yield(hit, hit.result)
      end
    end

    # 
    # The total number of documents matching the query parameters
    #
    # ==== Returns
    #
    # Integer:: Total matching documents
    #
    def total
      @total ||= solr_response['numFound']
    end

    # 
    # Get the facet object for the given name. `name` can either be the name
    # given to a query facet, or the field name of a field facet. Returns a
    # Sunspot::Facet object.
    #
    # ==== Parameters
    #
    # name<Symbol>::
    #   Name of the field to return the facet for, or the name given to the
    #   query facet when the search was constructed.
    # dynamic_name<Symbol>::
    #   If faceting on a dynamic field, this is the dynamic portion of the field
    #   name.
    #
    # ==== Example:
    #
    #   search = Sunspot.search(Post) do
    #     facet :category_ids
    #     dynamic :custom do
    #       facet :cuisine
    #     end
    #     facet :age do
    #       row 'Less than a month' do
    #         with(:published_at).greater_than(1.month.ago)
    #       end
    #       row 'Less than a year' do
    #         with(:published_at, 1.year.ago..1.month.ago)
    #       end
    #       row 'More than a year' do
    #         with(:published_at).less_than(1.year.ago)
    #       end
    #     end
    #   end
    #   search.facet(:category_ids)
    #     #=> Facet for :category_ids field
    #   search.facet(:custom, :cuisine)
    #     #=> Facet for the dynamic field :cuisine in the :custom field definition
    #   search.facet(:age)
    #     #=> Facet for the query facet named :age
    #
    def facet(name, dynamic_name = nil)
      if name
        if dynamic_name
          @facets_by_name[:"#{name}:#{dynamic_name}"]
        else
          @facets_by_name[name.to_sym]
        end
      end
    end

    # 
    # Deprecated in favor of optional second argument to #facet
    #
    def dynamic_facet(base_name, dynamic_name) #:nodoc:
      facet(base_name, dynamic_name)
    end

    # 
    # Get the data accessor that will be used to load a particular class out of
    # persistent storage. Data accessors can implement any methods that may be
    # useful for refining how data is loaded out of storage. When building a
    # search manually (e.g., using the Sunspot#new_search method), this should
    # be used before calling #execute(). Use the
    # Sunspot::DSL::Search#data_accessor_for method when building searches using
    # the block DSL.
    #
    def data_accessor_for(clazz) #:nodoc:
      (@data_accessors ||= {})[clazz.name.to_sym] ||=
        Adapters::DataAccessor.create(clazz)
    end

    # 
    # Build this search using a DSL block. This method can be called more than
    # once on an unexecuted search (e.g., Sunspot.new_search) in order to build
    # a search incrementally.
    #
    # === Example
    #
    #   search = Sunspot.new_search(Post)
    #   search.build do
    #     with(:published_at).less_than Time.now
    #   end
    #   search.execute!
    #
    def build(&block)
      Util.instance_eval_or_call(dsl, &block)
      self
    end

    # 
    # Populate the Hit objects with their instances. This is invoked the first
    # time any hit has its instance requested, and all hits are loaded as a
    # batch.
    #
    def populate_hits #:nodoc:
      id_hit_hash = Hash.new { |h, k| h[k] = {} }
      hits.each do |hit|
        id_hit_hash[hit.class_name][hit.primary_key] = hit
      end
      id_hit_hash.each_pair do |class_name, hits|
        ids = hits.map { |id, hit| hit.primary_key }
        data_accessor_for(Util.full_const_get(class_name)).load_all(ids).each do |result|
          hit = id_hit_hash[class_name][Adapters::InstanceAdapter.adapt(result).id.to_s]
          hit.result = result
        end
      end
    end

    def inspect #:nodoc:
      "<Sunspot::Search:#{query.to_params.inspect}>"
    end

    def add_field_facet(field, options = {}) #:nodoc:
      name = (options[:name] || field.name)
      add_facet(name, FieldFacet.new(field, self, options))
    end

    def add_date_facet(field, options) #:nodoc:
      name = (options[:name] || field.name)
      add_facet(name, DateFacet.new(field, self, options))
    end

    def add_query_facet(name, options) #:nodoc:
      add_facet(name, QueryFacet.new(name, self, options))
    end

    def facet_response #:nodoc:
      @solr_result['facet_counts']
    end

    private

    def solr_response
      @solr_response ||= @solr_result['response']
    end

    def dsl
      DSL::Search.new(self, @setup)
    end

    def highlights_for(doc)
      if @solr_result['highlighting']
        @solr_result['highlighting'][doc['id']]
      end
    end

    def distance_for(doc)
      if @solr_result['distances']
        @solr_result['distances'][doc['id']]
      end
    end

    def verified_hits
      @verified_hits ||= maybe_will_paginate(hits.select { |hit| hit.instance })
    end

    def maybe_will_paginate(collection)
      if defined?(WillPaginate::Collection)
        WillPaginate::Collection.create(@query.page, @query.per_page, total) do |pager|
          pager.replace(collection)
        end
      else
        collection
      end
    end
    
    # Clear out all the cached ivars so the search can be called again.
    def reset
      @results = @hits = @verified_hits = @total = @solr_response = @doc_ids = nil
    end

    def add_facet(name, facet)
      @facets << facet
      @facets_by_name[name.to_sym] = facet
    end
  end
end
