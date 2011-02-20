Feature: My Properties for Rent

  As an advertiser
  I would like to see a list of my properties for rent
  So that I can see when my adverts expire and make changes to them

  Scenario: Advertisers see no properties
    Given that I am signed in
    When I have no properties for rent
    And I am on the my properties for rent page
    Then I should see "no properties for rent"

  Scenario: Advertisers see properties
    Given that I am signed in
    When I have properties for rent
    And I am on the my properties for rent page
    Then I should not see "no properties for rent"

  Scenario: Advertisers can go to the new property for rent page
    Given that I am signed in
    And I am on the my properties for rent page
    When I follow "new property"
    Then I should be on the new property page

  Scenario: Advertisers can create a new property for rent
    Given that I am signed in
    And I am on the new property page
    When I fill in the following:
      | Name               | Chalet Des Sapins |
      | Weekly rent price  | 1650              |
      | Sleeping capacity  | 4                 |
      | Distance from lift | 1200              |
      | Number of bedrooms | 2                 |
    And I select "Chamonix" from "Resort"
    And I press "Save"
    Then my new property for rent has been saved
    And I should be on the my properties for rent page
    And I should see "Your property advert was successfully created."
    And I should see "Chalet Des Sapins"
