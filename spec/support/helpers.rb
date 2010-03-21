include Permit

def new_authz(person, key, resource = :default)
  role = Permit::Specs::Role.find_by_key key.to_s
  role ||= Permit::Specs::Role.create :key => key.to_s, :name => key.to_s
  resource = (resource == :default ? Permit::Specs::Project.find_or_create_by_name("test project") : resource)
  a = Permit::Specs::Authorization.create! :person => person, :role => role, :resource => resource
end

def role(key, name = nil)
  r = Permit::Specs::Role.find_by_key key.to_s
  r ? r : Permit::Specs::Role.create!(:key => key.to_s, :name => (name ? name : key.to_s))
end
