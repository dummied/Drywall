require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'ordering and pagination' do
  it 'paginates using default per_page when page not provided' do
    session.search Post
    connection.should have_last_search_with(:rows => 30)
  end

  it 'paginates using default per_page when page provided' do
    session.search Post do
      paginate :page => 2
    end
    connection.should have_last_search_with(:rows => 30, :start => 30)
  end

  it 'paginates using provided per_page' do
    session.search Post do
      paginate :page => 4, :per_page => 15
    end
    connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'defaults to page 1 if no :page argument given' do
    session.search Post do
      paginate :per_page => 15
    end
    connection.should have_last_search_with(:rows => 15, :start => 0)
  end

  it 'paginates from string argument' do
    session.search Post do
      paginate :page => '3', :per_page => '15'
    end
    connection.should have_last_search_with(:rows => 15, :start => 30)
  end

  it 'orders by a single field' do
    session.search Post do
      order_by :average_rating, :desc
    end
    connection.should have_last_search_with(:sort => 'average_rating_f desc')
  end

  it 'orders by multiple fields' do
    session.search Post do
      order_by :average_rating, :desc
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'average_rating_f desc, sort_title_s asc')
  end

  it 'orders by random' do
    session.search Post do
      order_by :random
    end
    connection.searches.last[:sort].should =~ /^random_\d+ asc$/
  end

  it 'orders by score' do
    session.search Post do
      order_by :score, :desc
    end
    connection.should have_last_search_with(:sort => 'score desc')
  end

  it 'throws an ArgumentError if a bogus order direction is given' do
    lambda do
      session.search Post do
        order_by :sort_title, :sideways
      end
    end.should raise_error(ArgumentError)
  end

  it 'throws an UnrecognizedFieldError if :distance is given for sort' do
    lambda do
      session.search Post do
        order_by :distance, :asc
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'does not allow ordering by multiple-value fields' do
    lambda do
      session.search Post do
        order_by :category_ids
      end
    end.should raise_error(ArgumentError)
  end

  it 'raises ArgumentError if bogus argument given to paginate' do
    lambda do
      session.search Post do
        paginate :page => 4, :ugly => :puppy
      end
    end.should raise_error(ArgumentError)
  end
end
