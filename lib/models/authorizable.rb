module Permit
  module Models
    module AuthorizableExtensions
      def self.included(klass)
        klass.extend AuthorizableClassMethods
        klass.extend Permit::Support::ClassMethods
      end

      module AuthorizableClassMethods
        def permit_authorizable
          return if include? Permit::Models::AuthorizableExtensions::AuthorizableInstanceMethods
          
          Permit::Config.authorizable_classes << self

          permit_authorized_model :as => :resource

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
