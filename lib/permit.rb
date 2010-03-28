require File.dirname(__FILE__) + '/permit/support'
require File.dirname(__FILE__) + '/permit/permit_rule'
require File.dirname(__FILE__) + '/permit/permit_rules'
require File.dirname(__FILE__) + '/permit/controller'
require File.dirname(__FILE__) + '/models/association'
require File.dirname(__FILE__) + '/models/role'
require File.dirname(__FILE__) + '/models/person'
require File.dirname(__FILE__) + '/models/authorization'
require File.dirname(__FILE__) + '/models/authorizable'

module Permit
  # allow|deny [:named_role|:person|:all|:guest|[]],
  #   (([:who|:that] => :method,)
  #   [:of|:on] => :instance_var,)
  #   :to => [:action|[]]
  #   (,:if => <method_name or proc>)
  #   (,:unless => <method_name or proc>)
  #

  # Raised when a {PermitRule} cannot be configured.
  class PermitConfigurationError < StandardError; end

  # Raised when an error occurs during evaluation of a {PermitRule}.
  class PermitEvaluationError < StandardError; end

  # Contains the configuration rules that Permit will apply during its 
  # processing.
  #
  # +role_class+, +authorization_class+, and +person_class+ are the model 
  # classes defined as representing their respective names by defining the 
  # corresponding <tt>permit_*</tt> method.   +authorizable_classes+ is an array 
  # of all classes that are authorizable to roles by having defined 
  # +permit_authorizable+.
  class Config
    @authorization_class, @person_class, @role_class = nil, nil, nil
    @authorizable_classes = []
    @controller_subject_method = nil


    @action_aliases = {
      :create => [:new, :create], 
      :update => [:edit, :update], 
      :destroy => [:delete, :destroy],
      :read => [:index, :show], 
      :write => [:new, :create, :edit, :update]
    }

    # Indicates the response returned by {PermitRules#permitted?} when no rules 
    # match. If set to +:allow+ then the person will be granted access. If set 
    # to anything else, they will be denied.
    @default_access = :deny

    class << self
      # Actions that when given to {PermitRules#allow}, and {PermitRules#deny} 
      # will be expanded into the actions given in the value array.
      #
      # Defaults to:
      #   {
      #     :create => [:new, :create], 
      #     :update => [:edit, :update], 
      #     :destroy => [:delete, :destroy],
      #     :read => [:index, :show], 
      #     :write => [:new, :create, :edit, :update]
      #   }
      attr_reader :action_aliases

      # The class that currently represents authorizations in the system, as set
      # by {set_core_models}.
      attr_reader :authorization_class
      # The class that currently represents authorization subjects in the
      # system, as set by {set_core_models}.
      attr_reader :person_class
      # The class that curretly represents roles in the system, as set by
      # {set_core_models}.
      attr_reader :role_class
      # Classes that are marked as authorizable resources using
      # {Permit::Models::AuthorizableExtensions::AuthorizableClassMethods#permit_authorizable permit_authorizable}.
      attr_reader :authorizable_classes

      #def action_aliases; @@action_aliases; end

      # Indicates the response that PermitRules will take if no
      # authorizations match. If set to +:allow+ then a subject will be given
      # access unless denied. By default this is set to +:deny+
      #
      # @return the current default access.
      def default_access; @default_access; end

      # Sets the response that PermitRules will use when no rules match.
      #
      # @param [:allow, :deny] access the default response to use.
      def default_access=(access); @default_access = access; end

      # The method to use to retrieve the current authorization subject when
      # rules are being evaluated. If nil, then the method will be inferred from
      # the subject set in the call to {set_core_models}.
      #
      # @return [Symbol, nil]
      def controller_subject_method; @controller_subject_method; end

      # Sets the name of the method to use to retrieve the current subject
      # while checking authorizations. Set to nil, to infer the value from the
      # subject set in {set_core_models}, or :current_person if named
      # authorizations are not being used.
      #
      # @param [nil, Symbol] method a symbol representing the method to use.
      def controller_subject_method=(method); @controller_subject_method = method; end

      # Sets the core authorization, person, and role models to be used for
      # named authorizations, and configures them with their respective permit_*
      # methods.
      #
      # @param [Class] authorization an ActiveRecord model representing
      #   authorizations.
      # @param [Class] person an ActiveRecord model representing
      #   people.
      # @param [Class] role an ActiveRecord model representing
      #   roles.
      def set_core_models(authorization, person, role)
        #raise PermitConfigurationError, "Core models cannot be redefined." if @@models_defined

        @authorization_class = authorization
        @person_class = person
        @role_class = role

        @authorization_class.send :permit_authorization
        @person_class.send :permit_person
        @role_class.send :permit_role
      end

      # Forces Permit to reload its core classes based off of those given in the
      # initial call to Permit::Config.set_core_models. This is primarily needed 
      # so that Permit will work in Rails development mode because of class 
      # caching/reloading. These variables hang onto the original models as they 
      # were defined and end up in a weird state. Production does not experience 
      # this problem.
      def reset_core_models
        authz = Object.const_get authorization_class.name
        person = Object.const_get person_class.name
        role = Object.const_get role_class.name
        Permit::Config.set_core_models(authz, person, role)
      end
    end
  end
end
