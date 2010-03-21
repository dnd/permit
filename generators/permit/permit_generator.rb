class PermitGenerator < Rails::Generator::Base
  default_options :setup_named_roles => true

  attr_reader :authorization_class, :role_class, :person_class
  def manifest
    record do |m|
      @person_class = (args.shift || 'Person').camelize
      @authorization_class = (args.shift || 'Authorization').camelize
      @role_class = (args.shift || 'Role').camelize

      m.template 'initializer.rb', 'config/initializers/permit.rb'

      if options[:setup_named_roles]
        m.template 'role.rb', "app/models/#{role_class.underscore}.rb"
        m.template 'authorization.rb', "app/models/#{authorization_class.underscore}.rb"
        m.migration_template 'migration.rb', "db/migrate", :migration_file_name => "create_permit_structure"
      end
    end
  end

protected
  def add_options!(opt)
    opt.on("--init-only", "Only generate the initializer file.") {|v| options[:setup_named_roles] = false}
  end
end
