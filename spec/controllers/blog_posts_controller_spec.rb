require 'spec_helper'

describe BlogPostsController do
  let(:website) { mock_model(Website).as_null_object }

  before do
    Website.stub(:first).and_return(website)
  end

  describe 'GET feed' do
    it 'finds all visible blog posts' do
      BlogPost.should_receive(:visible_posts)
      get 'feed', format: 'xml'
    end

    it 'assigns @blog_posts' do
      posts = BlogPost.new
      BlogPost.stub(:visible_posts).and_return(posts)
      get 'feed', format: 'xml'
      assigns('blog_posts').should == posts
    end
  end
end
