module Permit
  module Support
    module ClassMethods
      def class_symbol
        class_name.underscore.to_sym
      end

      def plural_class_symbol
        class_name.pluralize.underscore.to_sym
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
    def authorization_conditions(role, resource, person = nil)
      conditions = {}
      conditions[Permit::Config.person_class.name.foreign_key] = person.id if person
      conditions.merge! role_condition(role)
      conditions.merge! resource_conditions(resource)
    end

    def role_condition(roles)
      return {} unless roles

      r = get_roles(roles)
      ids = r.collect {|role| role.id}

      return (ids.empty? ? {} : {Permit::Config.role_class.name.foreign_key => ids})
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
