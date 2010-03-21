module Permit
  module Models
    module AuthorizableExtensions
      def self.included(klass)
        klass.extend AuthorizableClassMethods
      end

      module AuthorizableClassMethods
        def permit_authorizable
          return if include? Permit::Models::AuthorizableExtensions::AuthorizableInstanceMethods
          
          Permit::Config.authorizable_classes << self

          has_many :authorizations, :as => :resource, :extend => Permit::Models::AssociationExtensions

          def resource_type
            self.base_class.to_s
          end

          include Permit::Support
          include Permit::Models::AuthorizableExtensions::AuthorizableInstanceMethods          
        end

      end

      module AuthorizableInstanceMethods
      end
    end
  end
end
