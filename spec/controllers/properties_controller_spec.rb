require 'rails_helper'

describe PropertiesController do
  let(:property) { FactoryGirl.create(:property) }
  let(:website) { double(Website).as_null_object }
  let(:resort) { double(Resort).as_null_object }
  let(:non_admin_role) { double(Role).as_null_object }

  before do
    allow(Website).to receive(:first).and_return(website)
    allow(Resort).to receive(:find_by).and_return(resort)
    allow(non_admin_role).to receive(:admin?).and_return(false)
  end

  describe "GET index" do
    context "when signed in as admin" do
      before do
        allow(controller).to receive(:admin?).and_return(true)
      end

      it 'assigns @properties a page of properties ordered by id' do
        Property.delete_all
        properties = [
          FactoryGirl.create(:property),
          FactoryGirl.create(:property)
        ]
        get :index
        expect(assigns(:properties)).to eq(properties)
      end
    end

    context "when not signed in as admin" do
      it "redirects to the sign in page" do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:admin?).and_return(false)
        get :index
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  shared_examples 'a protector of hidden resorts' do |method, action|
    let(:resort) { FactoryGirl.create(:resort, visible: false) }

    context 'with search results' do
      before { allow(controller).to receive(:search_status).and_return 200 }

      it '404s hidden resorts' do
        send(method, action, resort_slug: resort.slug)
        expect(response.status).to eq 404
      end

      it 'shows hidden resorts to admin' do
        allow(controller).to receive(:admin?).and_return(true)
        send(method, action, resort_slug: resort.slug)
        expect(response.status).to eq 200
      end
    end

    context 'with no search results' do
      before { allow(controller).to receive(:search_status).and_return 404 }

      it '404s even for admin' do
        allow(controller).to receive(:admin?).and_return(true)
        send(method, action, resort_slug: resort.slug)
        expect(response.status).to eq 404
      end
    end
  end

  describe 'GET quick_search' do
    it_behaves_like 'a protector of hidden resorts', :get, :quick_search
  end

  describe 'GET browse_for_rent' do
    it_behaves_like 'a protector of hidden resorts', :get, :browse_for_rent
  end

  describe 'GET browse_for_sale' do
    it_behaves_like 'a protector of hidden resorts', :get, :browse_for_sale
  end

  describe 'GET browse_hotels' do
    it_behaves_like 'a protector of hidden resorts', :get, :browse_hotels
  end

  describe 'GET new_developments' do
    let(:properties) { double(ActiveRecord::Relation).as_null_object }

    before do
      rel = double(Property::ActiveRecord_Relation)
      allow(Property).to receive(:where).and_return(rel)
      allow(rel).to receive(:order).and_return(properties)
    end

    it_behaves_like 'a protector of hidden resorts', :get, :new_developments

    it 'finds a resort by its slug' do
      expect(Resort).to receive(:find_by).with(slug: 'chamonix').and_return(Resort.new)
      get :new_developments, resort_slug: 'chamonix'
    end

    it "finds paginated properties" do
      expect(properties).to receive(:paginate)
      get :new_developments, resort_slug: 'chamonix'
    end

    it "finds new developments" do
      expect(Property).to receive(:where).with(["publicly_visible = 1 AND resort_id = ? AND new_development = 1", resort.id]).and_return(properties)
      get :new_developments, resort_slug: 'chamonix'
    end

    it "assigns @properties" do
      get :new_developments, resort_slug: 'chamonix'
      expect(assigns[:properties]).to equal(properties)
    end
  end

  describe "GET new" do
    let(:current_user) { double(User).as_null_object }

    before do
      allow(controller).to receive(:signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(current_user).to receive(:role).and_return(non_admin_role)
    end

    context "with params[:listing_type] set" do
      it "sets property.listing_type to the given param" do
        get :new, listing_type: '1'
        expect(assigns(:property).listing_type).to eq 1
      end
    end

    context "with params[:listing_type] not set" do
      it "doesn't set property.listing_type" do
        expect_any_instance_of(Property).to_not receive(:listing_type=)
        get :new
      end
    end
  end

  describe 'GET update_day_of_month_select' do
    context 'when params[:year_month] is set' do
      it 'sets @year to the first four digits of year_month' do
        get 'update_day_of_month_select', year_month: '2012-13'
        expect(assigns(:year)).to eq(2012)
      end

      it 'sets @month to the 6th and 7th digits of year_month' do
        get 'update_day_of_month_select', year_month: '2012-13'
        expect(assigns(:month)).to eq(13)
      end
    end

    context 'when params[:year_month] is missing' do
      it 'sets @year to the current year' do
        get 'update_day_of_month_select'
        expect(assigns(:year)).to eq(Time.now.year)
      end

      it 'sets @month to the current month' do
        get 'update_day_of_month_select'
        expect(assigns(:month)).to eq(Time.now.month)
      end
    end
  end

  describe "POST create" do
    let(:current_user) { double(User).as_null_object }
    let(:role) { double(Role).as_null_object }
    let(:create_params) {{ id: '1', property: {name: 'A Property'}}}
    let(:property) { double(Property).as_null_object }

    before do
      session[:user] = 1
      allow(Advert).to receive(:create_for)
      allow(controller).to receive(:signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(current_user).to receive(:role).and_return(role)
      allow(Property).to receive(:new).and_return(property)
      allow(property).to receive(:user_id).and_return(1)
    end

    context "when the property saves successfully" do
      before do
        allow(property).to receive(:save).and_return(true)
      end

      context "when submitting in square feet" do
        it "converts square feet to square metres" do
          expect(Property).to receive(:new).with({
            "floor_area_metres_2"=>"93",
            "name"=>"A Property",
            "plot_size_metres_2"=>"186"
          })
          post 'create', { id: 1, property: {name: 'A Property', floor_area_metres_2: '1000', plot_size_metres_2: '2000'}, floor_area_unit: 'f', plot_area_unit: 'f' }
        end
      end

      context "when advertising through windows" do
        pending
      end

      context "when not advertising through windows" do
        before do
          allow(current_user).to receive(:advertises_through_windows?).and_return(false)
        end

        it "creates a corresponding advert" do
          expect(Advert).to receive(:create_for)
          post 'create', create_params
        end
      end

      it "redirects to image uploading form" do
        post 'create', create_params
        expect(response).to redirect_to(new_image_path)
      end
    end
  end

  describe 'GET contact' do
    def get_contact
      get :contact, id: '1'
    end

    it 'finds a property' do
      expect(Property).to receive(:find_by).with(id: '1')
      get_contact
    end

    it "assigns @resort from the property's resort" do
      allow(property).to receive(:resort).and_return(resort)
      allow(Property).to receive(:find_by).and_return(property)
      get_contact
      expect(assigns(:resort)).to eq resort
    end

    it 'assigns a new @enquiry linked to the property' do
      allow(Property).to receive(:find_by).and_return(property)
      get_contact
      expect(assigns(:enquiry)).to be
      expect(assigns(:enquiry).property).to eq property
    end
  end

  describe "GET show" do
    it "finds a property" do
      expect(Property).to receive(:find_by).with(id: '1')
      get :show, id: '1'
    end

    context "when a property is found" do
      let(:property) { double(Property).as_null_object }
      let(:resort) { double(Resort).as_null_object }
      let(:enquiry) { double(Enquiry).as_null_object }
      let(:property_owner) { double(User).as_null_object }

      before do
        allow(Property).to receive(:find_by).and_return(property)
        allow(Enquiry).to receive(:new).and_return(enquiry)
        allow(property).to receive(:resort).and_return(resort)
        allow(property).to receive(:user).and_return(property_owner)
        allow(property).to receive(:strapline).and_return('A strapline')
        allow(property).to receive(:interhome_accommodation).and_return(nil)
      end

      it "assigns @property" do
        get :show, id: '1'
        expect(assigns[:property]).to equal(property)
      end

      context 'when the property is publicly visible' do
        before do
          allow(property).to receive(:publicly_visible?).and_return(true)
        end

        context 'when a hotel' do
          before do
            allow(property).to receive(:hotel?).and_return(true)
          end

          it 'renders show_hotel' do
            get :show, id: '1'
            expect(response).to render_template :show_hotel
          end
        end

        context 'when a new development' do
          before do
            allow(property).to receive(:hotel?).and_return(false)
            allow(property).to receive(:new_development?).and_return(true)
          end

          it 'renders show_new_development' do
            get :show, id: '1'
            expect(response).to render_template :show_new_development
          end
        end

        context 'when neither a hotel nor new development nor FlipKey' do
          before do
            allow(property).to receive(:hotel?).and_return(false)
            allow(property).to receive(:new_development?).and_return(false)
            allow(property).to receive(:flip_key_property).and_return(nil)
          end

          it 'renders show' do
            get :show, id: '1'
            expect(response).to render_template :show
          end
        end
      end

      context "when the property is not publicly visible" do
        before do
          allow(property).to receive(:publicly_visible?).and_return(false)
          allow(property).to receive(:hotel?).and_return(false)
          allow(property).to receive(:new_development?).and_return(false)
          allow(property).to receive(:flip_key_property).and_return(nil)
        end

        context "when not signed in as admin" do
          before do
            allow(controller).to receive(:admin?).and_return(false)
          end

          context "but signed is as the owner" do
            let(:current_user) { double(User).as_null_object }

            it "shows the property" do
              signed_in_user
              allow(property).to receive(:user_id).and_return(current_user.id)
              get :show, { id: '1' }
              expect(response).to render_template('show')
            end
          end

          context "when not the owner either" do
            it "renders not found" do
              get :show, { id: '1' }
              expect(response.status).to eql 404
            end
          end
        end

        context "when signed in as admin" do
          it "shows the property" do
            allow(controller).to receive(:admin?).and_return(true)
            get :show, { id: '1' }
            expect(response).to render_template('show')
          end
        end
      end
    end

    context "when a property is not found" do
      before do
        allow(Property).to receive(:find_by).and_return(nil)
      end

      it "renders not found" do
        get :show, { id: '1' }
        expect(response.status).to eql 404
      end
    end
  end

  describe 'GET interhome_booking_form' do
    let!(:accommodation) { FactoryGirl.create(:interhome_accommodation) }

    context 'with vacancy information' do
      before do
        FactoryGirl.create(:interhome_vacancy, interhome_accommodation_id: accommodation.id)
      end

      it 'renders the default template' do
        get 'interhome_booking_form', id: accommodation.id
        expect(response).to render_template 'interhome_booking_form'
      end
    end

    context 'when vacancy information missing' do
      it 'renders the interhome_no_vacancy_info template' do
        get 'interhome_booking_form', id: accommodation.id
        expect(response).to render_template 'properties/interhome_no_vacancy_info'
      end
    end
  end

  def find_a_property_belonging_to_the_current_user
    expect(Property).to receive(:find_by).with(id: '1', user_id: anything())
  end

  def signed_in_user
    allow(controller).to receive(:signed_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(current_user)

    allow(current_user).to receive(:role).and_return(non_admin_role)
  end

  describe "GET edit" do
    let(:current_user) { double(User).as_null_object }
    let(:property) { double(Property).as_null_object }

    before do
      signed_in_user
    end

    it "finds a property belonging to the current user" do
      find_a_property_belonging_to_the_current_user
      get :edit, { id: '1' }
    end

    context "when a valid_property is found" do
      before do
        allow(Property).to receive(:find_by).and_return(property)
      end

      it "assigns @property" do
        get :edit, id: '1'
        expect(assigns[:property]).to equal(property)
      end
    end

    context "when a valid_property is not found" do
      before do
        allow(Property).to receive(:find_by).and_return(nil)
      end

      it "renders not found" do
        get :edit, { id: '1' }
        expect(response.status).to eql 404
      end
    end
  end

  describe "PUT update" do
    let(:current_user) { double(User).as_null_object }
    let(:image_id)     { nil }

    def put_update
      put 'update', id: '1', property: { title: 'T', image_id: image_id }
    end

    before do
      signed_in_user
    end

    it "finds a property belonging to the current user" do
      find_a_property_belonging_to_the_current_user
      put_update
    end

    context "when a valid property is found" do
      let(:property) { double(Property).as_null_object }

      before do
        allow(Property).to receive(:find_by).and_return(property)
      end

      context 'when image_id is set' do
        let(:property_owner) { FactoryGirl.create(:user) }
        let(:image)    { FactoryGirl.create(:image, source_url: '#', user: image_owner) }
        let(:image_id) { image.id }
        before         { allow(property).to receive(:user).and_return(property_owner) }

        context 'when image owned by property owner' do
          let(:image_owner) { property_owner }

          it 'sets the property image' do
            expect(property).to receive(:image=).with(image)
            put_update
          end
        end

        context 'when image not owned by property owner' do
          let(:image_owner) { FactoryGirl.create(:user) }

          it 'does not set the property image' do
            expect(property).not_to receive(:image=)
            put_update
          end
        end
      end

      context "when the property updates successfully" do
        before do
          allow(property).to receive(:update_attributes).and_return(true)
        end

        it "redirects to my adverts page" do
          allow(property).to receive(:for_sale?).and_return(false)
          put_update
          expect(response).to redirect_to(my_adverts_path)
        end

        it "sets a flash[:notice] message" do
          put_update
          expect(flash[:notice]).to eq("Your property advert details have been saved.")
        end
      end

      context "when the property fails to update" do
        before do
          allow(property).to receive(:update_attributes).and_return(false)
        end

        it "assigns @property" do
          put_update
          expect(assigns[:property]).to eq(property)
        end

        it "renders the edit template" do
          put_update
          expect(response).to render_template('edit')
        end
      end
    end

    context "when a valid property is not found" do
      before do
        allow(Property).to receive(:find_by).and_return(nil)
      end

      it "renders not found" do
        put :update, { id: '1' }
        expect(response.status).to eql 404
      end
    end
  end

  describe 'POST place_in_window' do
    let(:current_user) { double(User).as_null_object }

    before do
      signed_in_user
    end

    it "finds the user's property" do
      expect(Property).to receive(:find_by)
      post 'place_in_window', id: '1'
    end

    context "when the user's property is found" do
      before do
        allow(Property).to receive(:find_by).and_return(property)
      end

      it "finds the user's advert" do
        expect(Advert).to receive(:find_by)
        post 'place_in_window', id: '1'
      end

      context 'when an advert is found and it is a window' do
        let(:advert) { double(Advert).as_null_object }

        before do
          allow(Advert).to receive(:find_by).and_return(advert)
          allow(advert).to receive(:window?).and_return(true)
        end

        context 'when it has expired' do
          before do
            allow(advert).to receive(:expired?).and_return(true)
          end

          it 'sets a flash[:notice] message' do
            post 'place_in_window', id: '1'
            expect(flash[:notice]).to eq('That window has expired.')
          end

          it 'redirects to choose window' do
            post 'place_in_window', id: '1'
            expect(response).to redirect_to(action: 'choose_window')
          end
        end

        context 'when it has not expired' do
          before do
            allow(advert).to receive(:expired?).and_return(false)
          end

          it 'redirects to my adverts' do
            post 'place_in_window', id: '1'
            expect(response).to redirect_to(my_adverts_path)
          end
        end
      end
    end
  end
end
