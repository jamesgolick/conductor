class Instance < ActiveRecord::Base
  belongs_to :environment

  enum_field :size, %w( m1_small m1_large m1_xlarge c1_medium c1_xlarge )
  enum_field :role, %w( mysql_master app_server )
  enum_field :zone, %w( us_east_1a us_east_1b us_east_1c us_east_1d )

  validate :database_server_is_running

  protected
    def database_server_is_running
      if !environment.nil? && !mysql_master? && !environment.has_database_server?
        errors.add(:base, "You must launch a database server before you can launch an app server")
      end
    end
end
