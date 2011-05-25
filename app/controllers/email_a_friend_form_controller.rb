class EmailAFriendFormController < ApplicationController
  include SpamProtection

  before_filter :no_browse_menu

  def create
    @form = EmailAFriendForm.new(params[:email_a_friend_form])
    @property = Property.find(params[:email_a_friend_form][:property_id])
    if @form.valid?
      EmailAFriendNotifier.notify(@form, @property).deliver
      redirect_to @property, :notice => "We've sent your friend an email. Thanks for sharing My Ski Chalet."
    else
      render "properties/email_a_friend"
    end
  end
end