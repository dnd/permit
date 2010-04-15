# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{permit}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Steve Valaitis"]
  s.date = %q{2010-04-14}
  s.email = %q{steve@digitalnothing.com}
  s.extra_rdoc_files = [
    "README.mkd"
  ]
  s.files = [
    ".gitignore",
     ".yardopts",
     "MIT-LICENSE",
     "README.mkd",
     "Rakefile",
     "VERSION.yml",
     "generators/permit/USAGE",
     "generators/permit/permit_generator.rb",
     "generators/permit/templates/authorization.rb",
     "generators/permit/templates/initializer.rb",
     "generators/permit/templates/migration.rb",
     "generators/permit/templates/role.rb",
     "init.rb",
     "install.rb",
     "lib/models/association.rb",
     "lib/models/authorizable.rb",
     "lib/models/authorization.rb",
     "lib/models/person.rb",
     "lib/models/role.rb",
     "lib/permit.rb",
     "lib/permit/controller.rb",
     "lib/permit/permit_rule.rb",
     "lib/permit/permit_rules.rb",
     "lib/permit/support.rb",
     "permit.gemspec",
     "rails/init.rb",
     "spec/models/alternate_models_spec.rb",
     "spec/models/authorizable_spec.rb",
     "spec/models/authorization_spec.rb",
     "spec/models/person_spec.rb",
     "spec/models/role_spec.rb",
     "spec/permit/controller_spec.rb",
     "spec/permit/permit_rule_spec.rb",
     "spec/permit/permit_rules_spec.rb",
     "spec/permit_spec.rb",
     "spec/spec_helper.rb",
     "spec/support/helpers.rb",
     "spec/support/models.rb",
     "spec/support/permits_controller.rb",
     "tasks/permit_tasks.rake",
     "uninstall.rb"
  ]
  s.homepage = %q{http://github.com/dnd/permit}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A flexible authorization plugin for Ruby on Rails.}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/support/helpers.rb",
     "spec/support/models.rb",
     "spec/support/permits_controller.rb",
     "spec/models/alternate_models_spec.rb",
     "spec/models/person_spec.rb",
     "spec/models/role_spec.rb",
     "spec/models/authorizable_spec.rb",
     "spec/models/authorization_spec.rb",
     "spec/permit_spec.rb",
     "spec/permit/permit_rules_spec.rb",
     "spec/permit/controller_spec.rb",
     "spec/permit/permit_rule_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

