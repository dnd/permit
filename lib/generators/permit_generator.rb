require 'rails/generators'

class PermitGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  argument :person_name, :type => :string, :optional => true, :default => 'person'
  argument :authorization_name, :type => :string, :optional => true, :default => 'authorization'
  argument :role_name, :type => :string, :optional => true, :default => 'role'
  class_option 'init-only', :type => :boolean, :default => false, :banner => 'Only generate the initializer file.'

  def person_class
    person_name.camelize
  end

  def authorization_class
    authorization_name.camelize
  end

  def role_class
    role_name.camelize
  end

  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end

  def create_model_files
    return if options['init-only']
    generate :model, "#{authorization_name} --no-migration"
    generate :model, "#{role_name} --no-migration"
    migration_template 'migration.rb', 'db/migrate/create_permit_structure.rb' if Rails::Generators.options[:rails][:orm] == :active_record
  end

  def create_initializer
    template('initializer.rb', "config/initializers/permit.rb")
  end

  def self.next_migration_number(dirname)
    require 'rails/generators/active_record'
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end
end
