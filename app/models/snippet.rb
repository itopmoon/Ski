class Snippet < ActiveRecord::Base
  attr_accessible :locale, :name, :snippet

  validates_inclusion_of :locale, in: ['de', 'en', 'fr', 'it']
  validates_presence_of :name
  validates_uniqueness_of :name, scope: :locale
end
