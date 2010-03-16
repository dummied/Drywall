class RubyTubesday
	# Handles automatic parsing of responses for RubyTubesday.
	class Parser
		# Registers a parser method for a particular content type. When a
		# RubeTubesday instance receives a response with a registered content type,
		# the response body is passed to the associated parser method. The method
		# should return a parsed representation of the response body. For example,
		# the JSON parser is registered like so:
		#
		#   RubyTubesday::Parser.register(JSON.method(:parse), 'application/json')
		#
		# You can also specify more than one content type:
		#
		#   RubyTubesday::Parser.register(JSON.method(:parse), 'application/json', 'text/javascript')
		#
		# If a parser method is registered for a content type that already has a
		# parser, the old method is discarded.
		#
		def self.register(meth, *mime_types)
			mime_types.each do |type|
				@@parser_methods[type] = meth
			end
		end
		
		def self.parse(response) # :nodoc:
			content_type = response['Content-Type'].split(';').first
			parser_method = @@parser_methods[content_type]
			if parser_method
				parser_method.call(response.body)
			else
				response.body
			end
		end
		
	private
		
		@@parser_methods = {}
	end
end


# Register a parser for JSON if the json gem is installed.
begin
	require 'rubygems'
	require 'json'
	RubyTubesday::Parser.register(JSON.method(:parse), 'application/json')
rescue LoadError
	# Fail silently.
end
