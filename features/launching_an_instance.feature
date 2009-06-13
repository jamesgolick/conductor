Feature: As a user who has created an application and an environment
         I would like to be able to launch one or more instances
         So that I can deploy my application

  Scenario: Launching a database instance
    Given that I've created an environment called "production"
    When I go to the environment page for "production"
    And I follow "Launch Instance"
    And I select "mysql-master" from "Role"
    And I select "c1.medium" from "Size"
    And I select "us-east-1c" from "Availability Zone"
    And I press "Launch"
    Then I should see "Your instance(s) are being launched"
    And a "c1.medium" instance should be launched in "us-east-1c" as a "mysql-master"
    And I should be on the environment page for "production"

  Scenario: Launching a normal instance
    Given that I've created an environment called "production"
    Given that I've a running database instance
    When I go to the environment page for "production"
    And I follow "Launch Instance"
    And I select "app-server" from "Role"
    And I select "c1.medium" from "Size"
    And I select "us-east-1c" from "Availability Zone"
    And I press "Launch"
    Then I should see "Your instance(s) are being launched"
    And a "c1.medium" instance should be launched in "us-east-1c" as a "app-server"
    And I should be on the environment page for "production"

  Scenario: Launching a normal instance when there's no database instance running
    Given that I've created an environment called "production"
    When I go to the environment page for "production"
    And I follow "Launch Instance"
    And I select "app-server" from "Role"
    And I select "c1.medium" from "Size"
    And I select "us-east-1c" from "Availability Zone"
    And I press "Launch"
    Then I should not see "Your instance(s) are being launched"
    And no instances should be launched
    And I should see "No database instance is running"

