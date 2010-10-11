module Permit
  module Support
    module ClassMethods
      def class_symbol
        name.underscore.to_sym
      end

      def plural_class_symbol
        name.pluralize.underscore.to_sym
      end

      private
      def permit_authorized_model(custom_options = {})
        options = {:class_name => Permit::Config.authorization_class.name, :extend => Permit::Models::AssociationExtensions}.merge(custom_options)
        has_many Permit::Config.authorization_class.plural_class_symbol, options 

        class_eval <<-END
          protected
          def permit_authorizations_proxy
            #{Permit::Config.authorization_class.plural_class_symbol}
          end
        END
      end
    end

    # Converts an object to an array of that object if it is not already one.
    #
    # @param [Object] o the object to be made into an Array
    # @return [Array] the object as an array.
    def permit_arrayify(o)
      Array===o ? o : [o]
    end

    protected
    def authorization_conditions(roles, resources, person = nil)
      params = {}
      query = []
      if person
        query << "#{Permit::Config.person_class.name.foreign_key} = :person_id"
        params[:person_id] = person.id
      end
      query << role_condition(roles, params)
      query << resource_conditions(resources, params)

      [query.compact.join(" AND "), params]
    end

    def role_condition(roles, params = {})
      return nil unless roles

      r = get_roles(roles)
      ids = r.collect {|role| role.id}

      if ids.empty?
        return nil
      else
        params[:role_ids] = ids
        "#{Permit::Config.role_class.name.foreign_key} in (:role_ids)"
      end
    end

    def resource_conditions(resources, params = {})
      constraints = []
      permit_arrayify(resources).each_with_index do |resource, idx|
        type, id = case resource
        when :any then return nil
        when nil then [nil, nil]
        else [resource.class.resource_type, resource.id]
        end

        type_key = "resource_type_#{idx}".to_sym
        id_key = "resource_id_#{idx}".to_sym
        params.merge! type_key => type, id_key => id
        op = type.nil? ? 'is' : '='
        constraints << "(resource_type #{op} #{type_key.inspect} AND resource_id #{op} #{id_key.inspect})"
      end
      return "(" << constraints.join(" OR ") << ")"
    end

    def get_role(role)
      role.is_a?(Permit::Config.role_class) ? role : Permit::Config.role_class.find_by_key(role)
    end

    def get_roles(roles)
      permit_arrayify(roles).collect {|r| get_role(r)}.compact
    end
  end
end
