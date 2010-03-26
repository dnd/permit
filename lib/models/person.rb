module Permit
  module Models
    module PersonExtensions
      def self.included(klass)
        klass.extend PersonClassMethods
        klass.extend Permit::Support::ClassMethods
      end

      module PersonClassMethods
        # Defines the current model class as handling people for Permit.
        def permit_person
          return if include? Permit::Models::PersonExtensions::PersonInstanceMethods
          
          permit_authorized_model

          include Permit::Support
          include Permit::Models::PersonExtensions::PersonInstanceMethods
        end
      end

      module PersonInstanceMethods
        # Determines if the current person is authorized for any of the given 
        # role(s) and resource.
        #
        # @param [Role, String, Symbol, <Role, String, Symbol>] roles the roles 
        #   to check for authorization on.
        # @param [Authorizable, nil, :any] resource the resource to check for 
        #   authorization on.
        # @return [true, false] true if the person is authorized on any of the a  
        #   roles, false otherwise.
        def authorized?(roles, resource)
          permit_arrayify(roles).each do |r|
            role = get_role(r)
            next unless role
            conditions = authorization_conditions(role, resource)
            return true if permit_authorizations_proxy.exists?(conditions)
          end
          return false
        end

        # Determines if the current person is authorized for all of the given 
        # roles and resource.
        #
        # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
        #   roles the roles to check for authorization on.
        # @param [permit_authorizable, nil, :any] resource the resource to check for 
        #   authorization on.
        # @return [true, false] true if the person is authorized on all of the a  
        #   roles, false otherwise.
        def authorized_all?(roles, resource)
          permit_arrayify(roles).each do |r|
            role = get_role(r)
            return false unless role
            conditions = authorization_conditions(role, resource)
            return false unless permit_authorizations_proxy.exists?(conditions)
          end
          return true
        end

        # Authorizes the current person for all of the roles for the given 
        # resource, skipping any authorizations that the person already has. If 
        # there are any issues with the authorization an error will be raised.  
        # 
        # <em>The authorizations are run in a transaction. If an error is 
        # raised, *all* authorizations for the call will be rolled back.</em>
        #
        # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
        #   roles the roles to authorize the person on.
        # @param [permit_authorizable, nil] resource the resource to authorize 
        #   the person on.
        # @return [true] true if no errors occur during authorization.
        def authorize(roles, resource = nil)
          Permit::Config.authorization_class.transaction do
            permit_arrayify(roles).each do |r|
              role = get_role(r)
              next if authorized?(role, resource)

              authz = permit_authorizations_proxy.build
              authz.send("#{Permit::Config.role_class.class_symbol}=", role)
              authz.resource = resource
              authz.save!
            end
          end
          return true
        end

        # Revokes existing authorizations from the current person for the given 
        # roles and resource. If there are any issues with the revocation an 
        # error will be raised. Otherwise, the operation will return an Array of 
        # the Authorizations affected by the operation.
        #
        # This operation uses ActiveRecord's <tt>destroy_all</tt> method. For 
        # more information on what this means, please reference the ActiveRecord 
        # documentation.
        #
        # <em>The revocations are run in a transaction. If an error is raised, 
        # *all* revocations for the call will be rolled back.</em>
        #
        # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
        #   roles the roles to revoke from the person.
        # @param [permit_authorizable, nil, :any] resource the resource to 
        #   revoke roles for. If +:any+ is given then any authorizations for the 
        #   roles will be revoked.
        # @return [<permit_authorization>] the authorizations that were revoked.
        # @raise any errors that ActiveRecord encounters during processing.
        def revoke(roles, resource)
          remove_authorizations roles, resource do |conditions|
            Permit::Config.authorization_class.destroy_all conditions
          end
        end

        # Revokes existing authorizations from the current person for the given 
        # roles and resource. If there are any issues with the revocation an 
        # error will be raised. Otherwise, the operation will return the number 
        # of authorizations affected.
        #
        # This operation uses ActiveRecord's <tt>delete_all</tt> method. For 
        # more information on what this means, please reference the ActiveRecord 
        # documentation.
        #
        # <em>The revocations are run in a transaction. If an error is raised, 
        # *all* revocations for the call will be rolled back.</em>
        #
        # @param [permit_role, String, Symbol, <permit_role, String, Symbol>] 
        #   roles the roles to revoke from the person.
        # @param [permit_authorizable, nil, :any] resource the resource to 
        #   revoke roles for. If +:any+ is given then any authorizations for the 
        #   roles will be revoked.
        # @return [Fixnum] the number of authorizations revoked.
        # @raise any errors that ActiveRecord encounters during processing.
        def revoke!(roles, resource)
          remove_authorizations roles, resource do |conditions|
            Permit::Config.authorization_class.delete_all conditions
          end
        end

        protected
        def remove_authorizations(roles, resource)
          Permit::Config.authorization_class.transaction do
            conditions = authorization_conditions(roles, resource, self)
            yield conditions
          end
        end

      end
    end
  end
end
