class RubyTubesday
  class CachePolicy # :nodoc:
    def initialize(cache_control_header, options = {})
      # Extract options.
      @stored = options.delete(:stored)
      @shared = options.delete(:shared)
      @stored = false if @stored.nil?
      @shared = false if @shared.nil?
      
      unless options.empty?
        raise ArgumentError, "unrecognized keys: `#{options.keys.join('\', `')}'"
      end
      
      # Parse Cache-Control header.
      if cache_control_header.blank?
        @must_revalidate = true
      else
        directives = cache_control_header.split(',')
        directives.each do |directive|
          directive.sub!(/^ +/, '')
          directive.sub!(/ +$/, '')
          key, value = directive.split('=', 2)
          
          case key
          when 'public'          : @privacy = PUBLIC
          when 'private'         : @privacy = PRIVATE
          when 'no-cache'        : @storability = NO_CACHE
          when 'no-store'        : @storability = NO_STORE
          when 'max-age'         : @max_age = value.to_i
          when 's-maxage'        : @s_max_age = value.to_i
          when 'must-revalidate' : @must_revalidate = true
          end
        end
      end
    end
    
    # Indicates that a cached response must be refetched. Returned by fetch_action.
    REFETCH = :refetch
    # Indicates that a cached response must be revalidated. Returned by fetch_action.
    REVALIDATE = :revalidate
    # Indicates that a cached response may be used as-is. Returned by fetch_action.
    USE_CACHE = nil
    
    # Returns a constant indicating whether a cached response must be refetched
    # (returns REFETCH) or revalidated (returns REVALIDATE). Returns USE_CACHE if
    # the cached response may be used as-is. +response_age+ is the age of the
    # cached response in seconds.
    #
    # If you don't care about the distinction between refetching and
    # revalidating, you can treat the return value from this method as Boolean.
    def fetch_action(response_age)
      return REFETCH if @shared && @s_max_age && (response_age > @s_max_age)
      return REFETCH if @max_age && (response_age > @max_age)
      return REVALIDATE if @must_revalidate
      USE_CACHE
    end
    
    # Returns a Boolean value indicating whether a response is allowed to be
    # cached according to this cache policy.
    def may_cache?
      return false if @storability == NO_CACHE
      return false if @stored && @storability == NO_STORE
      return false if @shared && @privacy == PRIVATE
      true
    end
    
    def self.options_for_cache(cache)
      case cache
      when ActiveSupport::Cache::MemoryStore   : { :shared => false, :stored => false }
      when ActiveSupport::Cache::FileStore     : { :shared => true,  :stored => true  }
      when ActiveSupport::Cache::MemCacheStore : { :shared => true,  :stored => false }
      end
    end
  
  protected
    
    # Privacy levels
    PUBLIC  = :public
    PRIVATE = :private
    
    # Storability levels
    NO_CACHE = :no_cache
    NO_STORE = :no_store
  end
end
