class Thing
  include MongoMapper::Document
  include Sunspot::Rails::Searchable
  
  RELEVANCE_THRESHOLD = 2.0
  
  key :external_id, Integer
  key :title, String, :required => true, :allow_blank => false
  key :body, String, :required => true, :allow_blank => false
  key :link, String, :required => true, :unique => true, :allow_blank => false
  key :external_data, Hash
  key :extended_body, String, :required => true, :allow_blank => false
  key :tags, Array
  timestamps!
  
  belongs_to :source
  many :categories
  
  before_validation_on_create :extract
  before_create :sourcify, :hijack_update, :tag_this, :categorize
  after_save :listify
  
  searchable do
    text :extended_body, :boost => 2.0
    text :title
    text :tags, :boost => 3.0 do |p|
      p.tags.join(",")
    end
      
  end
  
  def tag_this
    self.tags = SemanticExtraction.find_keywords(extended_body)    
  end
  
  def categorize
    source.categories.each do |p|
      categories << p
    end
  end
  
  def hijack_update
    if thing = Thing.find_by_link(self.link)
      thing.update_attributes(self.attributes)
      thing.tag_this
      return false
    end
  end
  
  def sourcify
    root = link.match(/\w{3,5}:\/\/\w*\.(.+)\.\w{1,3}\/.*/)[1].gsub(".", "_")
    unless source = Source.find_by_slug(root)
      source = Source.new(:slug => root, :name => root.capitalize)
    end
    self.source = source
  end
  
  # Attempts to extract the extended_body, body and title from an arbitrary URL. By necessity, extended_body is very rough right now.
  # However, in limited testing, so far it is nailing the primary content div.
  def extract
    if extended_body.blank? || body.blank? || title.blank?
      http = RubyTubesday.new
      raw = http.get(link)
      data = Nokogiri::HTML(raw)
      no_body = false
    end
    if extended_body.blank?
      containers = (data/"div div")
      if containers.blank?
        text = raw
        no_body = true
      else
        possibles = []
        containers.each_with_index do |c, index|
          possibles << {:index => index, :count => ((c/"p").length - (c/"div").sum{|u| (u/"p").length})}
        end
        text_index = possibles.max{|a,b| a[:count] <=> b[:count]}[:index]
        text = containers[text_index]
        no_body = false
      end
      self.extended_body = Sanitize.clean(text.text)
    end
    if body.blank?
      if meta_desc = data.css("meta[name='description']").first 
        content = meta_desc['content']
      elsif no_body
        content = "No summary available"
      else
        content = Nokogiri::HTML(extended_body)
        content = content.css("p").first.text
      end
      self.body = content
    end
    if title.blank?
      self.title = data.css("title").first.children.first.to_s
    end
  end
  
  def genius
    if tags.blank?
      @things = []
    else
      unless @things
        query = tags.collect{|u| "'" + u + "'"}.join(" ")
        @things = Thing.search do
          keywords query, :minimum_match => 1
          paginate :per_page => 100
        end
        if @things.hits.blank?
          @things = []
        else
          @things = @things.hits.reject{|u| u.score < RELEVANCE_THRESHOLD}.collect{|c| c.result}.sort_by{|y| y.created_at}
        end
        if @things.length < 2
          @things = []
        end
      end
    end
    return @things
  end
  
  def lists
    List.all(:thing_ids => id)
  end
  
  def listify
    lists = List.all(:logic.ne => '')
    lists.each do |l|
      if l.contain(self)
        l.things << self
        l.save!
      end
    end
  end
  
end
