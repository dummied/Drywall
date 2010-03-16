class Fetch
  
  def self.single(feed_url, source=nil)
    http = RubyTubesday.new
    feed = Nokogiri::XML(http.get(feed_url))
    items = (feed/"item")
    if items.blank?
      items = (feed/"entry")
    end
    x = items.first
    if (x/"pubDate").first.blank? 
      if !(x/"modified").first.blank?
        trigger = "modified"
      else
        trigger = "published"
      end
    else
      trigger = "pubDate"
    end
    unless source.nil?             
      last_article = source.things.first(:order => "created_at")
      unless (x/trigger).blank?
        items = items.reject{|u| Time.parse((u/trigger).first.inner_html) < last_article.created_at} unless last_article.blank?
      end
    end
    items.reverse.each do |i|  
      begin      
        if (i/"link").first.inner_html.blank?
          link = (i/"link").first.get_attribute("href")
        else
          link = (i/"link").first.inner_html
        end
        if (i/"description").first.blank?
          body = (i/"summary").first.inner_html
        else
          body = (i/"description").first.inner_html
        end 
        if (i/trigger).first.blank?
          time = Time.now
        else
          time = Time.parse((i/trigger).first.inner_html)
        end
        if thing = Thing.find_by_link(link)
          thing = Thing.update_attributes!(
            :title => (i/"title").first.inner_html,
            :body => Sanitize.clean(body),
            :link => link,
            :created_at => time,
            :extended_body => nil,
            :tags => []
          )
        else   
           thing = Thing.new(
             :title => (i/"title").first.inner_html,
             :body => body,
             :link => link,
             :created_at => time
           )
           thing.source = source || Source.first(:feed_urls => feed_url)
           thing.save!
         end
       rescue
         next
       end   
    end
    
  end
  
  def self.all
    Source.all(:feed_urls.ne => []).each do |p|
      p.feed_urls.each do |f|
        self.single(f, p)
      end
    end
  end
  
  
end