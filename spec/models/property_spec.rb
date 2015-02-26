require 'rails_helper'

describe Property do
  # ActiveRecord
  it { should have_many(:images) }
  it { should have_many(:adverts) }

  # ActiveModel
  it { should ensure_length_of(:name).is_at_least(4).is_at_most(255) }
  it { should validate_presence_of(:resort) }
  it { should ensure_inclusion_of(:star_rating).in_range(1..5).with_message("is not in the range 1-5") }
  it { should respond_to(:star_rating) }
  it { should ensure_inclusion_of(:layout).in_array(Property::LAYOUTS) }

  describe '.parking_description' do
    pending
  end

  describe '#parking_description' do
    pending
  end

  describe '.tv_description' do
    pending
  end

  describe '#tv_description' do
    pending
  end

  describe '.board_basis_description' do
    pending
  end

  describe '#board_basis_description' do
    pending
  end

  describe '.normalise_prices' do
    pending
  end

  describe '.importable_attributes' do
    pending
  end

  describe '#to_param' do
    pending
  end

  describe '#for_rent?' do
    it 'returns true when listing_type is LISTING_TYPE_FOR_RENT' do
      property = Property.new(listing_type: Property::LISTING_TYPE_FOR_RENT)
      expect(property.for_rent?).to be_truthy
    end

    it 'returns false when listing_type is anything else' do
      property = Property.new(listing_type: Property::LISTING_TYPE_FOR_SALE)
      expect(property.for_rent?).to be_falsey
      property = Property.new(listing_type: Property::LISTING_TYPE_HOTEL)
      expect(property.for_rent?).to be_falsey
    end
  end

  describe '#for_sale?' do
    it 'returns true when listing_type is LISTING_TYPE_FOR_SALE' do
      property = Property.new(listing_type: Property::LISTING_TYPE_FOR_SALE)
      expect(property.for_sale?).to be_truthy
    end
  end

  describe '#hotel?' do
    it 'returns true when listing_type is LISTING_TYPE_HOTEL' do
      property = Property.new(listing_type: Property::LISTING_TYPE_HOTEL)
      expect(property.hotel?).to be_truthy
    end
  end

  describe '#price' do
    pending
  end

  describe '#features' do
    pending
  end

  describe '#adjust_distances_if_needed' do
    pending
  end

  describe '#closest_distance' do
    pending
  end

  describe '#geocode' do
    pending
  end

  describe '#attempt_geocode' do
    pending
  end

  describe '#normalise_prices' do
    pending
  end

  describe '#properties_for_rent_cannot_be_new_developments' do
    pending
  end

  describe '#valid_months' do
    let(:property) { Property.new }

    it "returns a sorted array of months from Property Base Prices" do
      PropertyBasePrice.delete_all
      PropertyBasePrice.create!([
        {number_of_months: 3,  price: 55},
        {number_of_months: 12, price: 149},
        {number_of_months: 6,  price: 89}
      ])
      expect(property.valid_months).to eq [3, 6, 12]
    end
  end

  describe '#cache_availability' do
    let(:interhome_accommodation) { FactoryGirl.create(:interhome_accommodation) }
    let(:property) { FactoryGirl.create(:property, interhome_accommodation: interhome_accommodation) }
    let!(:interhome_vacancy) { InterhomeVacancy.create!(
      interhome_accommodation_id: interhome_accommodation.id,
      startday: '2015-02-23',
      accommodation_code: 'AT0000.000.0',
      availability: 'NYQN',
      changeover: 'XCIO'
      ) }
    let(:d1) { Date.parse('2015-02-23') }
    let(:d2) { Date.parse('2015-02-24') }
    let(:d3) { Date.parse('2015-02-25') }
    let(:d4) { Date.parse('2015-02-26') }

    it 'creates multiple Availabilities' do
      property.cache_availability([d1, d2])
      expect(Availability.count).to eq 2
    end

    it 'records no availability' do
      property.cache_availability([d1])
      expect(Availability.first.availability).to eq Availability::UNAVAILABLE
    end

    it 'records availability' do
      property.cache_availability([d2])
      expect(Availability.first.availability).to eq Availability::AVAILABLE
    end

    it 'records no availability when no vacancy information' do
      property.cache_availability([Date.parse('2015-02-27')])
      expect(Availability.first.availability).to eq Availability::UNAVAILABLE
    end

    it 'records enquire for availability' do
      property.cache_availability([d3])
      expect(Availability.first.availability).to eq Availability::ENQUIRE
    end

    context 'for X' do
      before { property.cache_availability([d1]) }
      it 'records no check-in' do
        expect(Availability.first.check_in?).to be_falsey
      end
      it 'records no check-out' do
        expect(Availability.first.check_out?).to be_falsey
      end
    end

    context 'for C' do
      before { property.cache_availability([d2]) }
      it 'records check-in' do
        expect(Availability.first.check_in?).to be_truthy
      end
      it 'records check-out' do
        expect(Availability.first.check_out?).to be_truthy
      end
    end

    context 'for I' do
      before { property.cache_availability([d3]) }
      it 'records check-in' do
        expect(Availability.first.check_in?).to be_truthy
      end
      it 'records no check-out' do
        expect(Availability.first.check_out?).to be_falsey
      end
    end

    context 'for O' do
      before { property.cache_availability([d4]) }
      it 'records no check-in' do
        expect(Availability.first.check_in?).to be_falsey
      end
      it 'records check-out' do
        expect(Availability.first.check_out?).to be_truthy
      end
    end
  end

  describe '#default_months' do
    let(:property) { Property.new }

    context "when property is for sale" do
      it "returns 3" do
        property.listing_type = Property::LISTING_TYPE_FOR_SALE
        expect(property.default_months).to eq 3
      end
    end

    context "when property is for rent" do
      it "returns 12" do
        property.listing_type = Property::LISTING_TYPE_FOR_RENT
        expect(property.default_months).to eq 12
      end
    end
  end

  describe "#tidy_name_and_strapline" do
    let(:property) { Property.new }

    context "when the strapline is blank" do
      context "when the description is blank" do
        it "leaves the strapline blank" do
          property.tidy_name_and_strapline
          expect(property.strapline).to eq('')
        end
      end

      context "when the description is not blank" do
        it "leaves sets the strapline to the first 252 chars of description with an elipsis" do
          property.description = 'x' * 256
          property.tidy_name_and_strapline
          expect(property.strapline).to eq('x' * 252 + '...')
        end
      end
    end

    context "when the strapline is not blank" do
      it "truncates strapline to 252 chars with an elipsis" do
        property.strapline = 'x' * 256
        property.tidy_name_and_strapline
        expect(property.strapline).to eq('x' * 252 + '...')
      end
    end

    it "truncates name to 255 chars" do
      property.name = 'x' * 256
      property.tidy_name_and_strapline
      expect(property.name).to eq('x' * 255)
    end
  end

  describe '#calculate_late_availability' do
    context 'when not Interhome accommodation' do
      it 'returns true if the property is not for sale' do
        p = Property.new(listing_type: Property::LISTING_TYPE_FOR_RENT)
        expect(p.calculate_late_availability([])).to be_truthy
      end

      it 'returns false if the property is for sale' do
        p = Property.new(listing_type: Property::LISTING_TYPE_FOR_SALE)
        expect(p.calculate_late_availability([])).to be_falsey
      end
    end

    it 'returns the value of the Interhome accommodation availability' do
      available = InterhomeAccommodation.new
      expect(available).to receive(:available_to_check_in_on_dates?).and_return(true)
      p = Property.new
      p.interhome_accommodation = available
      expect(p.calculate_late_availability([])).to be_truthy

      unavailable = InterhomeAccommodation.new
      allow(unavailable).to receive(:available_to_check_in_on_dates?).and_return(false)
      p.interhome_accommodation = unavailable
      expect(p.calculate_late_availability([])).to be_falsey
    end
  end

  describe '#set_country_and_region' do
    let(:property) { FactoryGirl.build(:property) }

    before do
      @country = FactoryGirl.create(:country)
      @region = FactoryGirl.create(:region, country_id: @country.id)
      @resort = FactoryGirl.create(:resort, country_id: @country.id, region_id: @region.id)

      property.resort = @resort
      property.set_country_and_region
    end

    it 'sets country' do
      expect(property.country).to eq @country
    end

    it 'sets region' do
      expect(property.region).to eq @region
    end
  end

  describe '#template' do
    let(:flip_key_property) { nil }
    let(:property) { Property.new(layout: layout, flip_key_property: flip_key_property) }
    let(:hotel?) { false }
    let(:new_development?) { false }

    before do
      allow(property).to receive(:hotel?).and_return hotel?
      allow(property).to receive(:new_development?).and_return new_development?
    end

    subject { property.template }

    context 'when layout is set' do
      let(:layout) { 'Cool Layout' }
      it { should eq 'show_cool_layout' }
    end

    context 'when layout not set' do
      let(:layout) { nil }

      context 'when neither a hotel, new development or FlipKey' do
        it { should eq 'show_classic' }
      end

      context 'when a hotel' do
        let(:hotel?) { true }
        it { should eq 'show_hotel' }
      end

      context 'when a new development' do
        let(:new_development?) { true }
        it { should eq 'show_new_development' }
      end

      context 'when FlipKey' do
        let(:flip_key_property) { FactoryGirl.create(:flip_key_property) }
        it { should eq 'show_flip_key' }
      end
    end
  end

  describe 'before_save' do
    let(:property) { FactoryGirl.build(:property) }

    it 'calls set_country_and_region' do
      expect(property).to receive(:set_country_and_region)
      property.save
    end
  end
end
