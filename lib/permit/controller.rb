module Permit
  module ControllerExtensions
    def self.included(klass)
      klass.send :class_inheritable_accessor, :permit_rules
      klass.send :include, PermitInstanceMethods
      klass.send :extend, PermitClassMethods
      klass.send :permit_rules=, PermitRules.new(Rails.logger)
      klass.send :helper_method, :authorized?, :allowed?, :denied?

      # This is only needed in development mode since models are not cached, and
      # causes the models to end up in a weird state.  This forces Permit to
      # reestablish the core classes it uses internally.
      klass.send :before_filter, :reset_permit_core if Rails.env.development?
    end

    module PermitClassMethods
      # Creates a new block of Permit authorization rules, and sets the before 
      # filter to run them. The order of +deny+ and +allow+ rules do not matter. 
      # +deny+ rules will always be run first, and evaluation terminates on the 
      # first match.
      #
      # @example
      #   permit do
      #     deny :developer, :from => :all, :unless => Proc.new {(8..17).include?(Time.now.hour)}
      #     allow :person, :who => :is_member, :of => :team, :to => :read
      #     allow [:project_manager, :developer], :on => :project, :to => :all
      #   end
      #
      # @param [Hash] options (see PermitRules#initialize) for valid options.
      # @param [Block] &block the block containing the authorization rules.
      #
      # @see PermitRules#allow for syntax for +allow+ rules
      # @see PermitRules#deny for syntax for +deny+ rules
      def permit(options = {}, &block)
        rules = PermitRules.new(Rails.logger, options)
        rules.instance_eval(&block) if block_given?
        self.permit_rules = rules
        set_before_filter
      end

      private
      def set_before_filter
        unless (@before_filter_declared ||= false)
          before_filter :check_authorizations
          @before_filter_declared = true
        end
      end
    end

    module PermitInstanceMethods
      protected
      # Forces Permit to reload its core classes based off of those given in the
      # initial call to Permit::Config.set_core_models. You shouldn't have any
      # need to call this manually.
      def reset_permit_core
        authz = Object.const_get Permit::Config.authorization_class.class_name
        person = Object.const_get Permit::Config.person_class.class_name
        role = Object.const_get Permit::Config.role_class.class_name
        Permit::Config.set_core_models(authz, person, role)
        return true
      end

      # Called by {#check_authorizations} when a person is not authorized to 
      # access the current action. It calls +render_optional_error_file(401)+ on 
      # the controller, to render a Not Authorized error.
      #
      # If +#access_denied+ is already defined on the superclass, or redefined 
      # in the current controller then that will be called instead.
      #
      # @return [false] always returns false.
      def access_denied
        defined?(super) ? super : render_optional_error_file(401)
        return false
      end

      # Evaluates the Permit authorization rules for the current person on the 
      # current action. If the person is not permitted {#access_denied} will be 
      # called.
      def check_authorizations
        return access_denied unless self.permit_rules.permitted?(current_person, params[:action].to_sym, binding)
        true
      end

      # Creates a PermitRule with the arguments that are given, and attempts to 
      # match it based on the current person and binding context.
      #
      # For information on the parameters for this method see 
      # {PermitRule#initialize}.
      #
      # @return [Boolean] true if the rule matches, otherwise false.
      def allowed?(roles, options = {})
        rule = PermitRule.new roles, options
        rule.matches? current_person, binding
      end

      # Creates a PermitRule with the arguments that are given, and attempts to 
      # match it based on the current person and binding context.
      #
      # For information on the parameters for this method see 
      # {PermitRule#initialize}.
      #
      # @return [Boolean] true if the rule does not match, otherwise false.
      def denied?(roles, options = {})
        !allowed? roles, options
      end

      # Shortcut for +current_person#authorized?+. If the current person is a 
      # guest this will automatically return false.
      # 
      # For information on the parameters for this method see 
      # {Permit::Models::PersonExtensions::PersonInstanceMethods#authorized?}
      def authorized?(roles, resource)
        current_person.guest? ? false : current_person.authorized?(roles, resource)
      end
    end
  end
end
