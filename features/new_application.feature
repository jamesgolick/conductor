Feature: As a user
         I would like to create an application
         So that I can launch some infrastructure

  Scenario: Creating an application
    When I go to the new application page
    And I fill in "Name" with "conductor"
    And I fill in "Clone Url" with "git@github.com:giraffesoft/conductor.git"
    And I press "Create"
    Then I should see "Your application has been created."

