Feature: As a user who has created an application and an environment
         I would like to be able to launch one or more instances
         So that I can deploy my application

  Scenario: Launching a database instance
    Given that I've created an environment called "production"
    When I create a "mysql_master" instance
    Then I should see "Your instance(s) are being launched"
    And I should be on the environment page for "production"

  Scenario: Launching a normal instance
    Given that I've created an environment called "production"
    Given that I've launched a mysql_master instance in production
    When I create an "app_server" instance
    Then I should see "Your instance(s) are being launched"
    And I should be on the environment page for "production"

  Scenario: Launching a normal instance when there's no database instance running
    Given that I've created an environment called "production"
    When I create an "app_server" instance
    Then I should not see "Your instance(s) are being launched"
    And I should see "You must launch a database server"

