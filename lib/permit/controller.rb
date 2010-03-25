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
        filter_chain.delete_if {|f| f.method == :check_authorizations}
        before_filter :check_authorizations unless filter_chain.include?(:check_authorizations)
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
        return access_denied unless self.permit_rules.permitted?(permit_authorization_subject, params[:action].to_sym, binding)
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
        rule.matches? permit_authorization_subject, binding
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
        permit_authorization_subject.guest? ? false : permit_authorization_subject.authorized?(roles, resource)
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
