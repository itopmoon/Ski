class FlipKeyProperty < ActiveRecord::Base
  has_one :property, dependent: :destroy

  # Returns +true+ if:
  # * property is booked on the given date, or
  # * property calendar is missing, or
  # * date is in the past
  def booked_on?(date)
    if date < Date.today
      true
    elsif property_calendar['booked_date']
      property_calendar['booked_date'].any? { |bd| bd == date.to_s }
    else
      true
    end
  end

  # Returns an array of Dates where check-in is possible.
  def check_in_dates
    dates = []
    today = Date.today
    (0..365).each do |days|
      date = today + days.days
      dates << date if check_in_on?(date)
    end
    dates
  end

  def check_in_on?(date)
    !booked_on?(date)
  end

  def property_calendar
    parsed_json['property_calendar'][0]
  end

  def currency
    Currency.find_by(code: property_details['currency'][0])
  end

  def parsed_json
    @parsed_json ||= JSON.parse(json_data)
  end

  def latitude
    parsed_json['property_addresses'][0]['latitude'][0]
  end

  def longitude
    parsed_json['property_addresses'][0]['longitude'][0]
  end

  def location_description
    parsed_json['property_descriptions'][0]['property_description'][2]['description'][0]
  end

  def city
    parsed_json['property_addresses'][0]['city'][0]
  end

  def occupancy
    property_details['occupancy'][0].to_i
  end

  def bathroom_count
    if property_details['bathroom_count'][0].kind_of?(Hash)
      nil
    else
      property_details['bathroom_count'][0].to_i
    end
  end

  def bedroom_count
    property_details['bedroom_count'][0].to_i
  end

  def property_type
    property_details['property_type'][0]
  end

  def property_details
    parsed_json['property_details'][0]
  end

  def rental_price
    day_min_rate || week_min_rate || month_min_rate
  end

  def day_min_rate
    hash_nil(property_rate_summary['day_min_rate'][0])
  end

  def week_min_rate
    hash_nil(property_rate_summary['week_min_rate'][0])
  end

  def month_min_rate
    hash_nil(property_rate_summary['month_min_rate'][0])
  end

  def property_rate_summary
    parsed_json['property_rate_summary'][0]
  end

  def property_rates
    parsed_json['property_rates'][0]['property_rate']
  end

  def rental_price_scope
    return 'per night' if day_min_rate
    return 'per week' if week_min_rate
    return 'per month' if month_min_rate
    return ''
  end

  private

    def hash_nil(value)
      value.kind_of?(Hash) ? nil : value
    end
end
