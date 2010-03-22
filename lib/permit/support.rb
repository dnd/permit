module Permit
  module Support
    # Converts an object to an array of that object if it is not already one.
    #
    # @param [Object] o the object to be made into an Array
    # @return [Array] the object as an array.
    def permit_arrayify(o)
      Array===o ? o : [o]
    end

    protected
    def authorization_conditions(role, resource, person = nil)
      conditions = {}
      conditions[:person_id] = person.id if person
      conditions.merge! role_condition(role)
      conditions.merge! resource_conditions(resource)
    end

    def role_condition(roles)
      return {} unless roles

      r = get_roles(roles)
      ids = r.collect {|role| role.id}

      return (ids.empty? ? {} : {:role_id => ids})
    end

    def resource_conditions(resource)
      case resource
      when :any then {}
      when nil then {:resource_type => nil, :resource_id => nil}
      else {:resource_type => resource.class.resource_type, :resource_id => resource.id}
      end
    end

    def get_role(role)
      role.is_a?(Permit::Config.role_class) ? role : Permit::Config.role_class.find_by_key(role)
    end

    def get_roles(roles)
      permit_arrayify(roles).collect {|r| get_role(r)}.compact
    end
  end
end
