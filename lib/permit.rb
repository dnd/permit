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
    @@authorization_class, @@person_class, @@role_class = nil, nil, nil
    @@models_defined = false
    @@authorizable_classes = []

    # Actions that when given to {PermitRules#allow}, and {PermitRules#deny} 
    # will be expanded into the actions given in the value array.
    @@action_aliases = {
      :create => [:new, :create], 
      :update => [:edit, :update], 
      :destroy => [:delete, :destroy],
      :read => [:index, :show], 
      :write => [:new, :create, :edit, :update]
    }

    # Indicates the response returned by {PermitRules#permitted?} when no rules 
    # match. If set to +:allow+ then the person will be granted access. If set 
    # to anything else, they will be denied.
    @@default_access = :deny

    cattr_accessor :action_aliases
    cattr_accessor :default_access

    class << self
      def authorization_class; @@authorization_class; end
      def person_class; @@person_class; end
      def role_class; @@role_class; end
      def authorizable_classes; @@authorizable_classes; end
      def models_defined?; @@models_defined; end

      def set_core_models(authorization, person, role)
        #raise PermitConfigurationError, "Core models cannot be redefined." if @@models_defined

        @@authorization_class = authorization
        @@person_class = person
        @@role_class = role
        @@models_defined = true

        @@authorization_class.send :permit_authorization
        @@person_class.send :permit_person
        @@role_class.send :permit_role
      end
    end
  end
end
