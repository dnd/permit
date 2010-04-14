module Permit
  module Models
    # Defines a set of methods to extend the has_many :authorizations 
    # associations to help with querying for common cases. Some of these methods
    # do not show up in the documentation because they are dynamically created
    # with class_eval so that they can be explicit to the models you use for the
    # Person and Role models. See the documentation for {#method_missing} for
    # additionally created methods.
    module AssociationExtensions
      include Permit::Support

      # Finds all authorizations for the given resources
      #
      # @param [permit_authorizable, nil, :any, <permit_authorizable, nil>] 
      #   resource the resources to find authorizations for. :any may be given 
      #   to find matches for any resource.
      # @return [<permit_authorization>] the authorizations found for the resource.
      def for(resources)
        conditions = authorization_conditions(nil, resources)
        find(:all, :conditions => conditions)
      end

      # Finds all authorizations for the given role(s).
      #
      # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
      #   roles the roles to find authorizations for.
      # @return [<permit_authorization>] the authorizations found for the role(s).
      def as(roles)
        conditions = authorization_conditions(roles, :any)
        find(:all, :conditions => conditions)
      end

      # Finds all authorizations for the given resource and role(s).
      #
      # @param [permit_authorizable, nil, :any] resource the resource to find 
      #   authorizations for. :any may be given to find matches for any resource.
      # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
      #   roles the roles to find authorizations for.
      # @return [<permit_authorization>] the authorizations found for the resource and role(s)
      def for_resources_as(resources, roles)
        conditions = authorization_conditions(roles, resources)
        find(:all, :conditions => conditions)
      end

      # Finds all of the resources authorized for the given role(s).
      #
      # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
      #   roles the roles to find authorizations for.
      # @return [<permit_authorizable>] a unique list of resources authorized 
      #   for the role(s).
      def resources_as(roles)
        as(roles).collect(&:resource).uniq
      end

      # Defines three methods used for getting your subject models for a
      # resource, or as various roles, as well as role models for a given
      # resource.
      #
      # @overload people_for(resources)
      #   Finds all of the subjects that have authorizations for the given
      #   resources. Where "people" is the plural name of your subject model.
      #
      #   @param [permit_authorizable, nil, :any, <permit_authorizable, nil>] 
      #     resource the resources to find authorizations for. :any may be given 
      #     to find matches for any resource.
      #   @return [<permit_person>] a unique list of the people with 
      #     authorizations for the resource.
      #
      # @overload people_as(roles)
      #   Finds all of the subjects that have authorizations for the given
      #   role(s). Where "people" is the plural name of your subject model.
      #
      #   @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
      #     roles the roles to find authorizations for.
      #   @return [<permit_person>] a unique list of the people with 
      #     authorizations for the role(s).
      #
      # @overload roles_for(resources)
      #   Finds all of the roles authorized for the given resources. Where
      #   "roles" is the plural name of your role model.
      #
      #   @param [permit_authorizable, nil, :any, <permit_authorizable, nil>] 
      #     resource the resources to find authorizations for. :any may be given 
      #     to find matches for any resource.
      #   @return [<permit_role>] a unique list of roles authorized for the 
      #     resource.
      def method_missing(*args, &block); super; end

      def self.extended(klass)
        class_eval <<-END
          def #{Permit::Config.person_class.plural_class_symbol.to_s}_for(resources)
            self.for(resources).collect(&:#{Permit::Config.person_class.class_symbol.to_s}).uniq
          end

          def #{Permit::Config.person_class.plural_class_symbol.to_s}_as(roles)
            as(roles).collect(&:#{Permit::Config.person_class.class_symbol.to_s}).uniq
          end

          def #{Permit::Config.role_class.plural_class_symbol.to_s}_for(resources)
            self.for(resources).collect(&:#{Permit::Config.role_class.class_symbol.to_s}).uniq
          end
        END
      end
    end
  end
end
