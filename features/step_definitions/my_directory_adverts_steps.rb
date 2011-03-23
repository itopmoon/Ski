Given /^my business is called "([^"]*)"$/ do |arg1|
  alice.business_name = arg1
  alice.save
end

Given /^I have directory adverts$/ do
  DirectoryAdvert.create!(:user_id => alice.id, :category_id => categories(:bars).id, :business_address => '123 av')
end

Given /^I have no directory adverts$/ do
end
