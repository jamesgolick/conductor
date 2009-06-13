Feature: As a user who has created an application
         I would like to be able to add an environment
         So that I can start launching some instances

  Background:
    Given that I've created an application called "MyApp"
    When I go to the application page for "MyApp"
    And I follow "Add an Environment"

  Scenario: Creating an environment
    And I fill in "Name" with "production"
    And I press "Create"
    Then I should see "Your environment has been created"

  Scenario: Invalid parameters
    And I press "Create"
    Then I should not see "Your environment has been created"
    And I should see "Name can't be blank"

