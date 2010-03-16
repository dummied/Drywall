require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'search with dynamic fields' do
  it 'returns dynamic string facet' do
    stub_facet(:"custom_string:test_ss", 'two' => 2, 'one' => 1)
    result = session.search(Post) { dynamic(:custom_string) { facet(:test) }}
    result.facet(:custom_string, :test).rows.map { |row| row.value }.should == ['two', 'one']
  end

  it 'returns query facet specified in dynamic call' do
    stub_query_facet(
      'custom_string\:test_ss:(foo OR bar)' => 3
    )
    search = session.search(Post) do
      dynamic :custom_string do
        facet :test do
          row :foo_bar do
            with :test, %w(foo bar)
          end
        end
      end
    end
    facet = search.facet(:test)
    facet.rows.first.value.should == :foo_bar
    facet.rows.first.count.should == 3
  end
end
