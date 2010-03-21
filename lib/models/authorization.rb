module Permit
  module Models
    module AuthorizationExtensions
      def self.included(klass)
        klass.extend AuthorizationClassMethods
      end

      module AuthorizationClassMethods
        # Defines the current model class as handling authorizations for Permit.
        def permit_authorization
          return if include? Permit::Models::AuthorizationExtensions::AuthorizationInstanceMethods

          Permit::Config.authorization_class = self
          
          belongs_to :resource, :polymorphic => true
          belongs_to :person
          belongs_to :role

          validates_presence_of :person, :role
          validate :resource_presence
          validate :authorization_uniqueness

          include Permit::Models::AuthorizationExtensions::AuthorizationInstanceMethods
        end
      end

      module AuthorizationInstanceMethods
        protected
        def authorization_uniqueness
          return true unless person
          errors.add(:role,  "This person is already authorized for this resource") if person.authorized?(role, resource)
        end

        def resource_presence
          # Don't try to do anything if role isn't present
          return true unless role

          errors.add(:resource, :blank) if role.requires_resource? && resource.nil?
          errors.add(:resource, "Specific resources may not be granted for this role.") if !role.authorize_resource? && !resource.nil?
        end
      end
    end
  end
end
