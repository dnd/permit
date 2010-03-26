module Permit
  module Models
    module AuthorizationExtensions
      def self.included(klass)
        klass.extend AuthorizationClassMethods
        klass.extend Permit::Support::ClassMethods
      end

      module AuthorizationClassMethods
        # Defines the current model class as handling authorizations for Permit.
        def permit_authorization
          return if include? Permit::Models::AuthorizationExtensions::AuthorizationInstanceMethods
          
          belongs_to :resource, :polymorphic => true
          belongs_to Permit::Config.person_class.class_symbol, :class_name => Permit::Config.person_class.name
          belongs_to Permit::Config.role_class.class_symbol, :class_name => Permit::Config.role_class.name

          class_eval <<-END
            protected
            def permit_person_proxy
              #{Permit::Config.person_class.class_symbol.to_s}
            end

            def permit_role_proxy
              #{Permit::Config.role_class.class_symbol.to_s}
            end
          END

          validates_presence_of Permit::Config.person_class.class_symbol, Permit::Config.role_class.class_symbol
          validate :resource_presence
          validate :authorization_uniqueness

          include Permit::Models::AuthorizationExtensions::AuthorizationInstanceMethods
        end
      end

      module AuthorizationInstanceMethods
        protected
        def authorization_uniqueness
          return true unless permit_person_proxy
          errors.add(Permit::Config.role_class.class_symbol, "This person is already authorized for this resource") if permit_person_proxy.authorized?(permit_role_proxy, resource)
        end

        def resource_presence
          # Don't try to do anything if role isn't present
          return true unless permit_role_proxy

          errors.add(:resource, :blank) if permit_role_proxy.requires_resource? && resource.nil?
          errors.add(:resource, "Specific resources may not be granted for this role.") if !permit_role_proxy.authorize_resource? && !resource.nil?
        end
      end
    end
  end
end
