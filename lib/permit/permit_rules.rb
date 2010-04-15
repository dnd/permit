module Permit
  # Collection of PermitRule objects defining authorization.
  class PermitRules
    include Permit::Support

    attr_accessor :action_deny_rules, :action_allow_rules, :logger, :options

    # @param [#info] logger the logger to use when evaluating rules
    # @param [Hash] options the set of options to use during rule evaluation
    # @option options [Symbol] :default_access overrides the value in 
    #   Permit::Config#default_access to indicate how {#permitted?} will behave if 
    #   no rules match. 
    def initialize(logger, options = {})
      @action_deny_rules = {}
      @action_allow_rules = {}
      @logger = logger
      @options = options
    end

    # Determines if the person is permitted on the specified action by first 
    # evaluating deny rules, and then allow rules.  If the +:default_access+ 
    # option is set then its value will be used instead of the value from 
    # Permit::Config#default_access.
    #
    # @param [permit_person] person the person to check for authorization
    # @param [Symbol] action the action to check for authorization on.
    # @param [Binding] context_binding the binding to use to locate the resource 
    #   and/or process if/unless constraints.
    # @return [true, false] true if the person is permitted on the given action, 
    #   false otherwise.
    # @raise [PermitEvaluationError] if an error occurs while evaluating one of 
    #   the rules.
    def permitted?(person, action, context_binding)
      # Denial takes priority over allow
      return false if has_action_rule_match?(:deny, @action_deny_rules, person, action, context_binding)

      return true if has_action_rule_match?(:allow, @action_allow_rules, person, action, context_binding)

      # Default to no access if no rules match
      default_access = (@options[:default_access] || Permit::Config.default_access)
      return (default_access == :allow ? true : false)
    end

    # Adds an allow rule for the given actions to the collection.
    #
    # @example Allow a person that is a member of a team to show
    #   allow :person, :who => :is_member, :of => :team, :to => :show
    # @example Allow a person that is a member of any of the teams to index.
    #   allow :person, :who => :is_member, :of => [:team1, :team2], :to => :index
    # @example Allow a person with either of the named roles for a resource to perform any "write" operations.
    #   allow [:project_admin, :project_manager], :of => :project, :to => :write
    # @example Allow a person with the viewer role of either of the projects to show.
    #   allow :viewer, :of => [:project1, :project2], :to => :show
    #
    # @param [Symbol, <Symbol>] roles the role(s) that the rule will apply to.
    # @param [Hash] options the options used to build the rule.
    # @option options [Symbol] :who the method to call on the target resource.
    # @option options [Symbol] :that alias for :who
    # @option options [Symbol, nil, :any, <Symbol, nil>] :of the name of the instance variable holding the target 
    #   resource. If set to +:any+ then the match will apply to a person that has 
    #   a matching role authorization for any resource. If not given, or set to 
    #   +nil+, then the match will apply to a person that has a matching role 
    #   authorization for a nil resource. +:any/nil+ functionality only applies 
    #   when using named roles. (see Permit::NamedRoles).
    # @option options [Symbol, nil, :any, <Symbol, nil>] :on alias for +:of+
    # @option options [Symbol, String, Proc] :if code to evaluate at the end of the 
    #   match if it is still valid. If it returns false, the rule will not 
    #   match. If a proc if given, it will be passed the current subject and 
    #   binding. A method will be called without any arguments.    
    # @option options [Symbol, String, Proc] :unless code to evaluate at the end 
    #   of the match if it is still valid. If it returns true, the rule will not 
    #   match. If a proc if given, it will be passed the current subject and 
    #   binding. A method will be called without any arguments.    
    # @option options [Symbol, <Symbol>] :to the action(s) to allow access to if this 
    #   rule matches. +:all+ may be given to indicate that access is given to all 
    #   actions if the rule matches. Actions will be expanded using the aliases
    #   defined in {Permit::Config.action_aliases}. The expansion operation is
    #   not recursive.
    # @return [PermitRule] the rule that was created for the parameters.
    # @raise [PermitConfigurationError] if +:to+ is not valid, or if the rule 
    #   cannot be created.
    def allow(roles, options = {})
      actions = options.delete(:to)
      rule = PermitRule.new(roles, options)
      index_rule_by_actions @action_allow_rules, actions, rule
      return rule
    end

    # Adds an deny rule for the given actions to the collection.
    #
    # @example Deny a person that is a member of a project from :show
    #   deny :person, :who => :is_member, :of => :project, :from => :show
    # @example Deny a person with either of the named roles for a resource from writing.
    #   deny [:project_admin, :project_manager], :of => :project, :from => :write
    #
    # @param [Symbol, <Symbol>] roles the role(s) that the rule will apply to.
    # @param [Hash] options the options used to build the rule.
    # @option options [Symbol] :who the method to call on the target resource.
    # @option options [Symbol] :that alias for +:who+
    # @option options [Symbol] :of the name of the instance variable holding the target 
    #   resource. If set to +:any+ then the match will apply to a person that has 
    #   a matching role authorization for any resource. If not given, or set to 
    #   +nil+, then the match will apply to a person that has a matching role 
    #   authorization for a nil resource. :any/nil functionality only applies 
    #   when using named roles. (see Permit::NamedRoles).
    # @option options [Symbol] :on alias for +:of+
    # @option options [Symbol, String, Proc] :if code to evaluate at the end of the 
    #   match if it is still valid. If it returns false, the rule will not 
    #   match. The proc or method called, will be passed the current subject 
    #   being matched, and the binding being used.
    # @option options [Symbol, String, Proc] :unless code to evaluate at the end 
    #   of the match if it is still valid. If it returns true, the rule will not 
    #   match. The proc or method called, will be passed the current subject 
    #   being matched, and the binding being used.
    # @option options [Symbol, <Symbol>] :from the action(s) to deny access to if this 
    #   rule matches. +:all+ may be given to indicate that access is denied to all 
    #   actions if the rule matches. Actions will be expanded using the aliases
    #   defined in {Permit::Config.action_aliases}. The expansion operation is
    #   not recursive.
    # @return [PermitRule] the rule that was created for the parameters.
    # @raise [PermitConfigurationError] if +:from+ is not valid, or if the rule 
    #   cannot be created.
    def deny(roles, options = {})
      actions = options.delete(:from)
      rule = PermitRule.new(roles, options)
      index_rule_by_actions @action_deny_rules, actions, rule
      return rule
    end

    private
    def index_rule_by_actions(action_rules, actions, rule)
      determine_controlled_actions(actions).each do |a|
        (action_rules[a] ||= []) << rule
      end
    end

    def determine_controlled_actions(actions)
      actions = permit_arrayify(actions).compact
      raise PermitConfigurationError, "At least one action must be given to authorize access for." if actions.empty?
      raise PermitConfigurationError, "If :all is specified for :to/:from then no other actions may be given." if (actions.include?(:all) && actions.size > 1)
      expand_action_aliases actions
    end

    def expand_action_aliases(actions)
      expanded_actions = actions.collect {|a| Permit::Config.action_aliases[a] || a}
      expanded_actions.flatten.uniq
    end

    def has_action_rule_match?(type, rules, person, action, context_binding)
      applicable_rules = (rules[action] || []) + (rules[:all] || [])
      applicable_rules.each do |rule|
        if rule.matches?(person, context_binding) 
          @logger.info "#{person.inspect} matched #{type.to_s} rule: #{rule.inspect}"
          return true
        end
      end

      return false
    end
  end

end
