#require 'permit'

ActiveRecord::Base.send :include,
  Permit::Models::AuthorizationExtensions,
  Permit::Models::AuthorizableExtensions,
  Permit::Models::RoleExtensions,
  Permit::Models::PersonExtensions
