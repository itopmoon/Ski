require 'spec_helper'

describe ResortsController do
  let(:website) { mock_model(Website).as_null_object }
  let(:resort) { mock_model(Resort).as_null_object }

  before do
    Website.stub(:first).and_return(website)
    controller.stub(:admin?).and_return(false)
  end

  shared_examples 'a featured properties finder' do |action, params|
    before do
      Resort.stub(:find_by).and_return(mock_model(Resort, visible: true).as_null_object)
    end

    it 'assigns @featured_properties' do
      get action, params
      expect(assigns(:featured_properties)).to_not be_nil
    end
  end

  describe 'GET show' do
    it_behaves_like 'a featured properties finder', :show, id: 'chamonix'

    it 'finds a resort by its slug' do
      Resort.should_receive(:find_by).with(slug: 'chamonix').and_return(Resort.new)
      get :show, id: 'chamonix'
    end

    context 'when resort not found by slug' do
      before do
        Resort.stub(:find_by).with(slug: 'chamonix').and_return nil
      end

      it 'finds a resort by its ID' do
        Resort.should_receive(:find_by).with(id: 'chamonix')
        get :show, id: :chamonix
      end

      context 'when resort found by its ID' do
        before do
          Resort.should_receive(:find_by).with(id: 'chamonix').and_return resort
        end

        it 'permanently redirects to that resort' do
          get :show, id: 'chamonix'
          expect(response).to redirect_to resort
          expect(response.status).to eq 301
        end
      end
    end

    it 'assigns @resort' do
      Resort.stub(:find_by).and_return(resort)
      get :show, id: 'chamonix'
      expect(assigns[:resort]).to equal(resort)
    end
  end

  describe 'GET resort_guide' do
    it_behaves_like 'a featured properties finder', :resort_guide, id: 'chamonix'
  end

  describe 'GET summer_holidays' do
    let(:resort) { FactoryGirl.create(:resort) }

    before do
      controller.stub(:page_info).and_return page_info
      get :summer_holidays, id: resort.to_param
    end

    context 'with no page' do
      let(:page_info) { nil }

      it '404s' do
        expect(response.status).to eq 404
      end
    end

    context 'with invisible page' do
      let(:page_info) { Page.new(visible: false) }

      it '404s' do
        expect(response.status).to eq 404
      end
    end

    context 'with visible page' do
      let(:page_info) { Page.new(visible: true) }

      it 'renders' do
        expect(response).to be_success
      end
    end
  end
end
