begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError => e
  puts e
  puts "You need to install rspec in your base app"
  exit
end

ActiveRecord::Schema.verbose = false

begin
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
rescue ArgumentError
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :roles do |t|
    t.string :key, :name, :description
    t.boolean :requires_resource, :authorize_resource, :null => false, :default => true
  end

  create_table :people do |t|
    t.string :name
  end

  create_table :projects do |t|
    t.string :name
    t.integer :owner_id
  end

  create_table :teams do |t|
    t.string :name
  end

  create_table :people_teams, :id => false do |t|
    t.integer :person_id, :team_id
  end

  create_table :projects_teams, :id => false do |t|
    t.integer :project_id, :team_id
  end

  create_table :authorizations do |t|
    t.integer :person_id, :role_id, :null => false
    t.string :resource_type
    t.integer :resource_id
    t.timestamps
  end

  create_table :users do |t|
    t.string :name
  end
    
  create_table :jobs do |t|
    t.string :key, :name, :description
    t.boolean :requires_resource, :authorize_resource, :null => false, :default => true
  end

  create_table :entitlements do |t|
    t.integer :user_id, :job_id, :null => false
    t.string :resource_type
    t.integer :resource_id
    t.timestamps
  end

end

require File.dirname(__FILE__) + "/support/models"
require File.dirname(__FILE__) + "/support/permits_controller"
require File.dirname(__FILE__) + "/support/helpers"

Permit::Config.set_core_models(Permit::Specs::Authorization, Permit::Specs::Person, Permit::Specs::Role) #unless Permit::Config.models_defined?
