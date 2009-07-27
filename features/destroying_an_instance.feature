Feature: As a user
         I would like to be able to destroy an instance
         In order to reduce capacity (or for any number of other reasons)
        
  Scenario: Destroying an instance
    Given that I've created an application called "MyApp"
    Given that I've created an environment called "production"
    Given that I've launched a mysql_master instance in production
    When I go to the environment page for "production"
    And I follow "delete"
    Then I should see "0 instances running"
    And the instance should be terminated

