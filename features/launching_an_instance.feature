Feature: As a user who has created an application and an environment
         I would like to be able to launch one or more instances
         So that I can deploy my application

  Scenario: Launching a database instance
    Given that I've created an environment called "production"
    When I create a "mysql_master" instance
    Then I should see "Your instance(s) are being launched"
    And I should be on the environment page for "production"
    And I should see "1 instance running"
    And I should see "pending"
    And 1 instance should be running

  Scenario: Launching a normal instance
    Given that I've created an environment called "production"
    Given that I've launched a mysql_master instance in production
    When I create an "app" instance
    Then I should see "Your instance(s) are being launched"
    And I should be on the environment page for "production"
    And I should see "2 instances running"
    And I should see "pending"
    And 2 instances should be running

  Scenario: Launching a normal instance when there's no database instance running
    Given that I've created an environment called "production"
    When I create an "app" instance
    Then I should not see "Your instance(s) are being launched"
    And I should see "You must launch a database server"
    And no instances should be running

