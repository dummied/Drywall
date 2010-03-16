module Sunspot
  module Query
    class Dismax
      attr_writer :minimum_match, :phrase_slop, :query_phrase_slop, :tie

      def initialize(keywords)
        @keywords = keywords
        @fulltext_fields = {}
        @boost_queries = []
        @highlights = []
      end

      # 
      # The query as Solr parameters
      #
      def to_params
        params = { :q => @keywords }
        params[:fl] = '* score'
        params[:qf] = @fulltext_fields.values.map { |field| field.to_boosted_field }.join(' ')
        params[:defType] = 'dismax'
        if @phrase_fields
          params[:pf] = @phrase_fields.map { |field| field.to_boosted_field }.join(' ')
        end
        unless @boost_queries.empty?
          params[:bq] = @boost_queries.map do |boost_query|
            boost_query.to_boolean_phrase
          end
        end
        if @minimum_match
          params[:mm] = @minimum_match
        end
        if @phrase_slop
          params[:ps] = @phrase_slop
        end
        if @query_phrase_slop
          params[:qs] = @query_phrase_slop
        end
        if @tie
          params[:tie] = @tie
        end
        @highlights.each do |highlight|
          Sunspot::Util.deep_merge!(params, highlight.to_params)
        end
        params
      end

      # 
      # Assign a new boost query and return it.
      #
      def create_boost_query(factor)
        @boost_queries << boost_query = BoostQuery.new(factor)
        boost_query
      end

      # 
      # Add a fulltext field to be searched, with optional boost
      #
      def add_fulltext_field(field, boost = nil)
        @fulltext_fields[field.indexed_name] = TextFieldBoost.new(field, boost)
      end

      #
      # Add a phrase field for extra boost
      #
      def add_phrase_field(field, boost = nil)
        @phrase_fields ||= []
        @phrase_fields << TextFieldBoost.new(field, boost)
      end

      # 
      # Set highlighting options for the query. If fields is empty, the
      # Highlighting object won't pass field names at all, which means
      # the dismax's :qf parameter will be used by Solr.
      #
      def add_highlight(fields=[], options={})
        @highlights << Highlighting.new(fields, options)
      end

      # 
      # Determine if a given field is being searched. Used by DSL to avoid
      # overwriting boost parameters when injecting defaults.
      #
      def has_fulltext_field?(field)
        @fulltext_fields.has_key?(field.indexed_name)
      end
    end
  end
end
