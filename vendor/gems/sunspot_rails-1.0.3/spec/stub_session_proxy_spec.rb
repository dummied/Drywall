require File.join(File.dirname(__FILE__), 'spec_helper')
require File.join(File.dirname(__FILE__), '..', 'lib', 'sunspot', 'rails', 'spec_helper')

describe 'specs with Sunspot stubbed' do
  disconnect_sunspot

  before :each do
    @session = Sunspot.session.original_session
    @post = Post.create!
  end

  it 'should not send index to session' do
    @session.should_not_receive(:index)
    @post.index
  end

  it 'should not send index! to session' do
    @session.should_not_receive(:index!)
    @post.index!
  end

  it 'should not send commit to session' do
    @session.should_not_receive(:commit)
    Sunspot.commit
  end

  it 'should not send remove to session' do
    @session.should_not_receive(:remove)
    @post.remove_from_index
  end

  it 'should not send remove! to session' do
    @session.should_not_receive(:remove)
    @post.remove_from_index!
  end

  it 'should not send remove_by_id to session' do
    @session.should_not_receive(:remove_by_id)
    Sunspot.remove_by_id(Post, 1)
  end

  it 'should not send remove_by_id! to session' do
    @session.should_not_receive(:remove_by_id!)
    Sunspot.remove_by_id!(Post, 1)
  end

  it 'should not send remove_all to session' do
    @session.should_not_receive(:remove_all)
    Post.remove_all_from_index
  end

  it 'should not send remove_all! to session' do
    @session.should_not_receive(:remove_all!)
    Post.remove_all_from_index!
  end

  it 'should return false for dirty?' do
    @session.should_not_receive(:dirty?)
    Sunspot.dirty?.should == false
  end

  it 'should not send commit_if_dirty to session' do
    @session.should_not_receive(:commit_if_dirty)
    Sunspot.commit_if_dirty
  end

  it 'should return false for delete_dirty?' do
    @session.should_not_receive(:delete_dirty?)
    Sunspot.delete_dirty?.should == false
  end

  it 'should not send commit_if_delete_dirty to session' do
    @session.should_not_receive(:commit_if_delete_dirty)
    Sunspot.commit_if_delete_dirty
  end

  it 'should not execute a search when #search called' do
    @session.should_not_receive(:search)
    Post.search
  end

  it 'should not execute a search when #search called' do
    @session.should_not_receive(:search)
    Post.search
  end

  it 'should return a new search' do
    @session.should_not_receive(:new_search)
    Sunspot.new_search(Post).should respond_to(:execute)
  end

  describe 'stub search' do
    before :each do
      @search = Post.search
    end

    it 'should return empty results' do
      @search.results.should == []
    end

    it 'should return empty hits' do
      @search.hits.should == []
    end

    it 'should return zero total' do
      @search.total.should == 0
    end

    it 'should return nil for a given facet' do
      @search.facet(:category_id).should be_nil
    end

    it 'should return nil for a given dynamic facet' do
      @search.dynamic_facet(:custom).should be_nil
    end
  end
end
