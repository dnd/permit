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
      # @param [Hash] options options to use when evaluating this block of
      #   authorizations.
      # @option options [:allow, :deny] :default_access overrides the
      #   {Permit::Config.default_access} setting.
      # @param [Block] &block the block containing the authorization rules. See
      #   {PermitRules#allow} and {PermitRules#deny} for the syntax for the
      #   respective types of rules.
      def permit(options = {}, &block)
        rules = PermitRules.new(Rails.logger, options)
        rules.instance_eval(&block) if block_given?
        self.permit_rules = rules
        set_permit_before_filter
      end

      private
      def set_permit_before_filter
        # Remove check_authorizations if it was set in a super class so that
        # other before filters that possibly set the needed resource have a
        # chance to run.
        before_filter :check_authorizations
      end
    end

    module PermitInstanceMethods
      protected
      # Needed to reset the core models in development mode as they were defined
      # in the initializer for Permit.
      def reset_permit_core
        Permit::Config.reset_core_models
        return true
      end

      # Evaluates the Permit authorization rules for the current person on the 
      # current action. 
      #
      # When the person is not permitted, +#access_denied+ will be called if it 
      # exists. Otherwise Permit::NotAuthorized will be raised.
      #
      # @raise [Permit::NotAuthorized] if the person is not permitted, and an 
      # +#access_denied+ method does not exist.
      #
      # @return [Boolean] true if the person is permitted, otherwise false
      def check_authorizations
        if self.permit_rules.permitted?(permit_authorization_subject, params[:action].to_sym, binding)
          true
        else
          defined?(access_denied) ? access_denied : raise(Permit::NotAuthorized)
        end
      end

      # Determines if a person is allowed access by evaluating rules for a 
      # controller/action, or for a custom rule.
      #
      # @overload allowed?(roles, options = {}) 
      #   Creates a PermitRule with the arguments that are given, and attempts 
      #   to match it based on the current subject and binding context.
      #
      #   For information on the parameters for this method see 
      #   {PermitRule#initialize}.
      #
      #   @return [Boolean] true if the rule matches, otherwise false.
      #
      # @overload allowed?(options)
      #   Attempts to evaluate the rules for the given action against the 
      #   specified controller using the current subject, and binding context.
      #
      #   Keep in mind that the evaluation is performed using the binding of the 
      #   current controller. Any instance variables that may normally be needed 
      #   for the rules on another controller need to exist in the current 
      #   controller.
      #
      #   @param [Hash] options the controller/action to evaluate rules for.
      #   @option options [String, Symbol] controller the name of the controller to 
      #     evaluate the rules from. If this is not given then the current 
      #     controller is used. You may use the string syntax 'namespaced/teams' 
      #     for a namespaced controller Namespaced::TeamsController.
      #   @option options [Symbol] action the action to evaluate rules for.
      #
      #   @return [Boolean] true if the rule matches, otherwise false.
      def allowed?(*args)
        options = args.extract_options!
        if options.has_key? :action
          name = options[:controller]
          klass = (name ? "#{name}_controller".camelize.constantize : self)
          klass.permit_rules.permitted? permit_authorization_subject, options[:action], binding
        else
          rule = PermitRule.new args[0], options
          rule.matches? permit_authorization_subject, binding
        end
      end

      # Determines if a person is denied access by evaluating rules for a 
      # controller/action, or for a custom rule.
      #
      # @overload denied?(roles, options = {}) 
      #   Creates a PermitRule with the arguments that are given, and attempts 
      #   to match it based on the current subject and binding context.
      #
      #   For information on the parameters for this method see 
      #   {PermitRule#initialize}.
      #
      #   @return [Boolean] true if the rule does not match, otherwise false.
      #
      # @overload denied?(options)
      #   Attempts to evaluate the rules for the given action against the 
      #   specified controller using the current subject, and binding context.
      #
      #   Keep in mind that the evaluation is performed using the binding of the 
      #   current controller. Any instance variables that may normally be needed 
      #   for the rules on another controller need to exist in the current 
      #   controller.
      #
      #   @param [Hash] options the controller/action to evaluate rules for.
      #   @option options [String, Symbol] controller the name of the controller to 
      #     evaluate the rules from. If this is not given then the current 
      #     controller is used. You may use the string syntax 'namespaced/teams' 
      #     for a namespaced controller Namespaced::TeamsController.
      #   @option options [Symbol] action the action to evaluate rules for.
      #
      #   @return [Boolean] true if the subject is denied, otherwise false.
      def denied?(*args)
        !allowed? *args
      end

      # Shortcut for +current_person#authorized?+. If the current person is a 
      # guest this will automatically return false.
      # 
      # For information on the parameters for this method see 
      # {Permit::Models::PersonExtensions::PersonInstanceMethods#authorized?}
      def authorized?(roles, resources)
        permit_authorization_subject.guest? ? false : permit_authorization_subject.authorized?(roles, resources)
      end

    private
      def permit_authorization_subject
        return send(@controller_subject_method) if @controller_subject_method

        @controller_subject_method = if Permit::Config.controller_subject_method
          Permit::Config.controller_subject_method
        elsif Permit::Config.person_class
          klass_name = Permit::Config.person_class.class_name.underscore
          "current_#{klass_name}".to_sym
        else
          :current_person
        end

        send(@controller_subject_method)
      end
    end
  end
end
