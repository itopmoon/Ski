require 'spec_helper'

module LateAvailability
  describe Finder do
    describe '#find_featured' do
      it 'returns at most 5 properties when limit is 5' do
        6.times { create_featured_late_availability_property! }
        finder = Finder.new
        finder.find_featured(limit: 5).length.should == 5
      end

      it 'returns all late availability properties when limit is unset' do
        6.times { create_featured_late_availability_property! }
        finder = Finder.new
        finder.find_featured().length.should == 6
      end
    end

    def create_featured_late_availability_property!
      @resort ||= Resort.create!(name: 'late availability resort')
      @currency ||= Currency.create!(name: 'sterling', code: 'gbp', in_euros: 1)

      Property.create!(
        late_availability: true,
        resort: @resort,
        address: 'address',
        name: 'property',
        currency: @currency,
        user_id: 1
      )
    end
  end
end