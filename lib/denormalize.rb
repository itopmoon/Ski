class Denormalize
  def self.denormalize
    Property.find_in_batches(batch_size: 250, include: [:resort]) do |properties|
      properties.each do |p|
        publicly_visible = p.currently_advertised? && p.resort.visible?
        country_id = p.resort.country_id
        if p.publicly_visible != publicly_visible || p.country_id != country_id
          p.publicly_visible = publicly_visible
          p.country_id = country_id
          p.save
        end
      end
      sleep(0.5)
    end

    Resort.visible.each do |resort|
      resort.for_rent_count = count_properties(resort, :listing_type, Property::LISTING_TYPE_FOR_RENT)
      resort.for_sale_count = count_properties(resort, :listing_type, Property::LISTING_TYPE_FOR_SALE)
      resort.hotel_count = count_properties(resort, :listing_type, Property::LISTING_TYPE_HOTEL)
      resort.new_development_count = count_properties(resort, :new_development, true)
      resort.property_count = resort.for_rent_count + resort.for_sale_count + resort.hotel_count + resort.new_development_count
      resort.save
    end

    Country.with_visible_resorts.each do |country|
      country.property_count = country.visible_resorts.inject(0) {|c, r| c + r.property_count}
      country.save
    end
  end

  def self.count_properties(resort, attribute, value)
    Property.where(resort_id: resort.id, publicly_visible: true, attribute => value).count
  end
end