require 'spec_helper'

feature 'Resorts admin' do
  fixtures :countries, :holiday_types, :regions, :roles, :users, :websites

  scenario 'Add resort to region from resort page' do
    bow
    sign_in_as_admin
    visit admin_resorts_path
    click_link 'Edit Bowness-on-Windermere'
    select 'Lake Windermere', from: 'Region'
    click_button 'Save'
    expect(Resort.find_by(name: 'Bowness-on-Windermere').region.name).to eq 'Lake Windermere'
  end

  scenario 'Edit additional page' do
    bow
    sign_in_as_admin
    visit edit_admin_resort_path(bow)
    click_link 'Edit summer-holidays page'
    expect(page).to have_content 'Edit Page'
  end

  scenario 'Link holiday type' do
    bow
    sign_in_as_admin
    visit edit_admin_resort_path(bow)
    select 'Lakes & Mountains', from: 'Holiday type'
    click_button 'Link Holiday Type'
    expect(page.find('#holiday-types table')).to have_content('Lakes & Mountains')
  end

  scenario 'Unlink holiday type' do
    bow
    ResortHolidayType.create!(resort: bow, holiday_type: holiday_types(:lakes_and_mountains))
    sign_in_as_admin
    visit edit_admin_resort_path(bow)
    within '#holiday-types table' do
      click_link 'Delete'
    end
    expect(page).to have_content 'Deleted'
    expect(page).not_to have_css('#holiday-types table')
  end

  def bow
    @bow ||= FactoryGirl.create(:resort, name: 'Bowness-on-Windermere', country: countries(:united_kingdom))
  end
end
