module Permit
  module Models
    # Defines a set of methods to extend the has_many :authorizations 
    # associations to help with querying for common cases.
    module AssociationExtensions
      include Permit::Support

      # Finds all authorizations for the given resource
      #
      # @param [permit_authorizable, nil, :any] resource the resource to find 
      #   authorizations for. :any may be given to find matches for any resource.
      # @return [<permit_authorization>] the authorizations found for the resource.
      def for(resource)
        conditions = authorization_conditions(nil, resource)
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
      def for_resource_as(resource, roles)
        conditions = authorization_conditions(roles, resource)
        find(:all, :conditions => conditions)
      end

      # Finds all of the people that have authorizations for the given resource.
      #
      # @param [permit_authorizable, nil, :any] resource the resource to find 
      #   authorizations for. :any may be given to find matches for any resource.
      # @return [<permit_person>] a unique list of the people with 
      #   authorizations for the resource.
      def people_for(resource)
        self.for(resource).collect(&:person).uniq
      end

      # Finds all of the people that have authorizations for the given role(s).
      #
      # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
      #   roles the roles to find authorizations for.
      # @return [<permit_person>] a unique list of the people with 
      #   authorizations for the role(s).
      def people_as(roles)
        as(roles).collect(&:person).uniq
      end

      # Finds all of the roles authorized for the given resource.
      #
      # @param [permit_authorizable, nil, :any] resource the resource to find 
      #   authorizations for. :any may be given to find matches for any resource.
      # @return [<permit_role>] a unique list of roles authorized for the 
      #   resource.
      def roles_for(resource)
        self.for(resource).collect(&:role).uniq
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
    end
  end
end
