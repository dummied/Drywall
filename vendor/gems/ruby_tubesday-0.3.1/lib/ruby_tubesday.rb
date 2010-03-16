require 'uri'
require 'cgi'
require 'net/https'
require 'rubygems'
require 'active_support'

require 'ruby_tubesday/parser'
require 'ruby_tubesday/cache_policy'

# RubyTubesday is a full-featured HTTP client. It supports automatic parsing
# of content bodies, caching, redirection, verified SSL, and basic
# authentication.
#
# If you have the json gem, RubyTubesday will automatically parse JSON
# responses. You can add parsers for other content types with the
# RubyTubesday::Parser class.
#
# == Example
#
#   require 'rubygems'
#   require 'ruby_tubesday'
#   
#   http = RubyTubesday.new :params => { :api_key => '12345', :output => 'json' }
#   result = http.get 'http://maps.google.com/maps/geo', :params => { :q => '123 Main Street' }
#   lat_lng = result['Placemark'].first['Point']['coordinates']
#
class RubyTubesday
	# Thrown when a request is redirected too many times.
	class TooManyRedirects < Exception; end
	
	# Creates a new HTTP client. Accepts the following options:
	#
	# raw::             Whether to always return raw content bodies. If this is
	#                   false, content types registered with RubyTubesday::Parser
	#                   will be automatically parsed for you. Default is false.
	# cache::           An instance of an ActiveSupport::Cache subclass to use
	#                   as a content cache. You can set this to false to disable
	#                   caching. Default is a new MemoryStore.
	# force_cache::     An amount of time to cache requests, regardless of the
	#                   request's cache control policy. Default is nil.
	# params::          Parameters to include in every request. For example, if
	#                   the service you're accessing requires an API key, you can
	#                   set it here and it will be included in every request made
	#                   from this client.
	# max_redirects::   Maximum number of redirects to follow in a single request
	#                   before throwing an exception. Default is five.
	# ca_file::         Path to a file containing certifying authority
	#                   certificates (for verifying SSL server certificates).
	#                   Default is the CA bundle included with RubyTubesday,
	#                   which is a copy of the bundle included with CentOS 5.
	# verify_ssl::      Whether to verify SSL certificates. If a certificate
	#                   fails verification, the request will throw an exception.
	#                   Default is true.
	# username::        Username to send using basic authentication with every
	#                   request.
	# password::        Username to send using basic authentication with every
	#                   request.
	# headers::         Hash of HTTP headers to set for every request.
	#
	# All of these options can be overriden on a per-request basis.
	def initialize(options = {})
		@default_options = {
			:raw           => false,
			:cache         => ActiveSupport::Cache::MemoryStore.new,
			:force_cache   => nil,
			:params        => {},
			:max_redirects => 5,
			:ca_file       => (File.dirname(__FILE__) + '/../ca-bundle.crt'),
			:verify_ssl    => true,
			:username      => nil,
			:password      => nil,
			:headers       => nil
		}
		@default_options = normalize_options(options)
	end
	
	# Fetches a URL using the GET method. Accepts the same options as new.
	# Options specified here are merged into the options specified when the
	# client was instantiated.
	#
	# Parameters in the URL will be merged with the params option. The params
	# option supercedes parameters specified in the URL. For example:
	#
	#   # Fetches http://example.com/search?q=ruby&lang=en
	#   http.get 'http://example.com/search?q=ruby', :params => { :lang => 'en' }
	#
	#   # Fetches http://example.com/search?q=ruby&lang=ja
	#   http.get 'http://example.com/search?q=ruby&lang=en', :params => { :lang => 'ja' }	
	#
	def get(url, options = {})
		options = normalize_options(options)
		url = URI.parse(url)
		
		url_params = CGI.parse(url.query || '')
		params = url_params.merge(options[:params])
		query_string = ''
		unless params.empty?
			params.each do |key, values|
				values = [values] unless values.is_a?(Array)
				values.each do |value|
					query_string += "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}&"
				end
			end
			query_string.chop!
			url.query = query_string
			query_string = "?#{query_string}"
		end
		request = Net::HTTP::Get.new(url.path + query_string)
		
		process_request(request, url, options)
	end
	
	# Sends data to a URL using the POST method. Accepts the same options as new.
	# Options specified here are merged into the options specified when the
	# client was instantiated.
	#
	# Parameters in the URL will be ignored. The post body will be URL-encoded.
	#
	# This method never uses the cache.
	#
	def post(url, options = {})
		options = normalize_options(options)
		url = URI.parse(url)
		
		request = Net::HTTP::Post.new(url.path)
		request.set_form_data(options[:params])
		
		process_request(request, url, options)
	end
  
protected
	
	def normalize_options(options) # :nodoc:
		normalized_options = {
			:raw           => options.delete(:raw),
			:cache         => options.delete(:cache),
			:force_cache   => options.delete(:force_cache),
			:params        => options.delete(:params)        || @default_options[:params],
	    :max_redirects => options.delete(:max_redirects) || @default_options[:max_redirects],
	    :ca_file       => options.delete(:ca_file)       || @default_options[:ca_file],
	    :verify_ssl    => options.delete(:verify_ssl),
	    :username      => options.delete(:username)      || @default_options[:username],
	    :password      => options.delete(:password)      || @default_options[:password],
	    :headers       => options.delete(:headers)       || @default_options[:headers]
	  }
	  
    normalized_options[:raw]         = @default_options[:raw]         if normalized_options[:raw].nil?
    normalized_options[:cache]       = @default_options[:cache]       if normalized_options[:cache].nil?
    normalized_options[:force_cache] = @default_options[:force_cache] if normalized_options[:force_cache].nil?
    normalized_options[:verify_ssl]  = @default_options[:verify_ssl]  if normalized_options[:verify_ssl].nil?
    
    unless options.empty?
      raise ArgumentError, "unrecognized keys: `#{options.keys.join('\', `')}'"
    end
    
    normalized_options
	end
	
	def process_request(request, url, options) # :nodoc:
		response = nil
		cache_policy_options = CachePolicy.options_for_cache(options[:cache]) || {}
		
		# Check the cache first if this is a GET request.
		if request.is_a?(Net::HTTP::Get) && options[:cache] && options[:cache].read(url.to_s)
			response = Marshal.load(options[:cache].read(url.to_s))
			response_age = Time.now - Time.parse(response['Last-Modified'] || response['Date'])
			cache_policy = CachePolicy.new(response['Cache-Control'], cache_policy_options)
			if (options[:force_cache] && (options[:force_cache] < response_age)) || cache_policy.fetch_action(response_age)
				response = nil
			end
		end
		
		# Cache miss. Fetch the entity from the network.
		if response.nil?
			redirects_left = options[:max_redirects]
			
			# Configure headers.
			headers = options[:headers] || {}
			headers.each do |key, value|
			  request[key] = value
		  end
			
			while !response.is_a?(Net::HTTPSuccess)
				client = Net::HTTP.new(url.host, url.port)
				
				# Configure authentication.
				if options[:username] && options[:password]
					request.basic_auth options[:username], options[:password]
				end
				
				# Configure SSL.
				if (client.use_ssl = url.is_a?(URI::HTTPS))
					client.verify_mode = options[:verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
					client.ca_file = options[:ca_file]
				end
				
				# Send the request.
				response = client.start { |w| w.request(request) }
				
				if response.is_a?(Net::HTTPRedirection)
					raise(TooManyRedirects) if redirects_left < 1
					url = URI.parse(response['Location'])
					request = Net::HTTP::Get.new(url.path)
					redirects_left -= 1
				elsif !response.is_a?(Net::HTTPSuccess)
					response.error!
				end
			end
			
			# Write the response to the cache if we're allowed to.
			if request.is_a?(Net::HTTP::Get) && options[:cache]
				cache_policy = CachePolicy.new(response['Cache-Control'], cache_policy_options)
				if cache_policy.may_cache? || options[:force_cache]
					options[:cache].write(url.to_s, Marshal.dump(response))
				end
			end
		end
    
    # Return the response.
    if options[:raw]
	    response.body
	  else
	  	RubyTubesday::Parser.parse(response)
	  end
  end
end
