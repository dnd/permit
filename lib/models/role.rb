module Permit
  module Models
    module RoleExtensions
      def self.included(klass)
        klass.extend RoleClassMethods
      end

      module RoleClassMethods
        def permit_role
          return if include? Permit::Models::RoleExtensions::RoleInstanceMethods

          Permit::Config.role_class = self

          has_many :authorizations, :extend => Permit::Models::AssociationExtensions

          validates_presence_of :key, :name
          validates_inclusion_of :requires_resource, :authorize_resource, :in => [true, false]
          validates_uniqueness_of :key, :case_sensistive => false
          validate :resource_requirement

          # Finds the role by its key, preparing the passed in value before 
          # querying.
          #
          # @param [String, Symbol] val the key value
          # @return [Role, nil] the role that matches the key. nil if none are 
          #   found.
          def find_by_key(val)
            find(:first, :conditions => {:key => prepare_key(val)})
          end

          # Prepares the key value for use.
          #
          # @param [String, Symbol] val the key value
          # @return [String] the formatted key value.
          def prepare_key(val)
            val.nil? ? val : val.to_s.downcase
          end

          include Permit::Support
          include Permit::Models::RoleExtensions::RoleInstanceMethods
        end
      end

      module RoleInstanceMethods
        # Sets the key for the role with extra processing to convert it from a 
        # symbol and downcase it.
        #
        # @param [String, Symbol] val the key value.
        def key=(val)
          write_attribute :key, self.class.prepare_key(val)
        end

        protected
        def resource_requirement
          errors.add(:requires_resource, "cannot be true if authorize_resource is false") if !authorize_resource? && requires_resource?
        end
      end
    end
  end
end
