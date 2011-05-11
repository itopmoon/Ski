class EmailAFriendForm
  include ActiveModel::Validations

  attr_accessor :property_id, :your_name, :your_email, :friends_name, :friends_email

  validates_presence_of :property_id, :your_name, :your_email, :friends_name, :friends_email

  validates_format_of :your_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_format_of :friends_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  def initialize(params = nil)
    unless params.nil?
      @property_id = params[:property_id]
      @your_name = params[:your_name]
      @your_email = params[:your_email]
      @friends_name = params[:friends_name]
      @friends_email = params[:friends_email]
    end
  end

  def to_key
    ["1"]
  end

  def to_param
    to_key
  end
end
