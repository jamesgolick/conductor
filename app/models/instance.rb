class Instance < ActiveRecord::Base
  belongs_to :environment

  enum_field :size, %w( m1.small m1.large m1.xlarge c1.medium c1.xlarge )
  enum_field :role, %w( mysql-master app-server )
  enum_field :zone, %w( us-east-1a us-east-1b us-east-1c us-east-1d )
end
