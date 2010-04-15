module Permit
  # Defines an authorization rule to match against.
  class PermitRule
    include Permit::Support
    
    VALID_OPTION_KEYS = [:who, :that, :of, :on, :if, :unless]
    BUILTIN_ROLES = [:person, :guest, :everyone]

    attr_reader :roles, :target_vars, :method, :if, :unless

    # Creates a new PermitRule.
    #
    # +:if+ and +:unless+ conditions may be evaluated for static, dynamic, and 
    # named authorizations. They are evaluated after the other rule checks are 
    # applied, and only if the rule still matches. The conditionals may make a 
    # matching rule not match, but will not make an unmatched rule match. If 
    # both +:if+ and +:unless+ are given the +:if+ condition is run first, and 
    # if the rule still matches the +:unless+ will be run.
    #
    # @param [:person, :guest, :everyone, Symbol, <Symbol>] roles the role(s) to 
    #   test against.
    #   - :person - +current_person.guest? == false+ This person should be 
    #     authenticated. This indicates a dynamic authorization.
    #   - :guest - +current_person.guest? == true+ This is a person that is not 
    #     authenticated. This is a static authorization.
    #   - :everyone - Any user of the system. This is a static authorization.
    #   - Symbol/<Symbol> - This is the key or keys of any of the role(s) to 
    #     match against in the database. This indicates a named authorization.
    # @param [Hash] options the options to use to configure the authorization.
    # @option options [Symbol] :who Indicates that a method should be checked on 
    #   the target object to authorize. Checks a variety of possibilities, 
    #   taking the first variation that the target responds to. 
    #
    #   When the symbol is prefixed with 'is_' then multiple methods will be 
    #   tried passing the person in. The methods tried for +:is_owner+ would be 
    #   +is_owner()+, +is_owner?()+, +owner()+, +owner+, +owners.exist?()+. If 
    #   this option is given +:of+/+:on+ must also be given.
    # @option options [Symbol] :that alias for +:who+
    # @option options [Symbol, nil, :any, <Symbol, nil>] :of The name of the 
    #   instance variable(s) to use as the target resource(s).
    #
    #   In a dynamic authorization this is the object that will be tested using 
    #   the value of +:who+/+:that+.
    #
    #   In a named authorization this is the resource the person must be 
    #   authorized on for one or more of the roles. +:any+ may be given to 
    #   indicate a match if the person has one of the roles for any resource. If 
    #   not given, or set to +nil+, then the match will apply to a person that 
    #   has a matching role authorization for a nil resource. 
    # @option options [Symbol, nil, :any, <Symbol, nil>] :on alias for +:of+
    # @option options [Symbol, String, Proc] :if code to evaluate at the end of the 
    #   match if it is still valid. If it returns false, the rule will not 
    #   match. If a proc if given, it will be passed the current subject and 
    #   binding. A method will be called without any arguments.    
    # @option options [Symbol, String, Proc] :unless code to evaluate at the end of 
    #   the match if it is still valid. If it returns true, the rule will not 
    #   match. If a proc if given, it will be passed the current subject and 
    #   binding. A method will be called without any arguments.    
    #
    # @raise [PermitConfigurationError] if the rule options are invalid.
    def initialize(roles, options = {})
      options.assert_valid_keys *VALID_OPTION_KEYS

      @roles = validate_roles(roles).freeze

      validate_options options

      @method = options[:who] || options[:that]
      @target_vars = permit_arrayify(options[:of] || options[:on]).uniq.freeze

      @if = options[:if]
      @unless = options[:unless]
    end

    # Determine if the passed in person matches this rule.
    #
    # @param [permit_person] person the person to evaluate for authorization
    # @param [Binding] context_binding the binding to use to locate the resource 
    #   and/or evaluate the if/unless conditions.
    # @return [Boolean] true if the person matches the rule, otherwise 
    #   false.
    # @raise [PermitEvaluationError] if there is a problem evaluating the rule.
    def matches?(person, context_binding)
      matched = if BUILTIN_ROLES.include? @roles[0]
        has_builtin_authorization? person, context_binding
      else
        has_named_authorizations? person, context_binding
      end

      passed_conditionals = matched ? passes_conditionals?(person, context_binding) : false
      passed = matched && passed_conditionals
      return passed
    end

    private
    def validate_roles(roles)
      roles = permit_arrayify(roles).compact.uniq
      raise PermitConfigurationError, "At least one role must be specified." if roles.empty?
      raise PermitConfigurationError, "Only one role may be specified when using :person, :guest, or :everyone" if (roles & BUILTIN_ROLES).size > 0 && roles.size > 1
      roles.freeze
    end

    def validate_options(options)
      if (options[:of] || options[:on]) && @roles[0] == :person
        raise PermitConfigurationError, "When :of or :on are specified for the :person role a corresponding :who or :that must be given" unless options[:who] || options[:that]
      end

      if options[:who] || options[:that]
        raise PermitConfigurationError, "The :who and :that options are only valid for the :person role." unless @roles[0] == :person
        raise PermitConfigurationError, "When :who or :that is specified a corresponding :of or :on must be given" unless options[:of] || options[:on]
      end

      raise PermitConfigurationError, "Either :who or :that may be specified, but not both." if  options[:who] && options[:that]
      raise PermitConfigurationError, "Either :of or :on may be specified, but not both." if options[:of] && options[:on]
    end

    def has_builtin_authorization?(person, context_binding)
      case @roles[0]
        when :everyone then true
        when :guest then person.guest?
        when :person then has_dynamic_authorization? person, context_binding
        else false
      end
    end

    def has_named_authorizations?(person, context_binding)
      return false if person.guest?
      resources = []
      @target_vars.each do |var_name|
        resources << case var_name
          when nil then nil
          when :any then (resources = :any and break)
          else get_resource(var_name, context_binding)
        end
      end
      person.authorized? @roles, resources
    end

    def has_dynamic_authorization?(person, context_binding)
      return false if person.guest?

      methods = determine_method_sequence @method

      @target_vars.each do |var_name|
        return true if var_name.nil?

        resource = get_resource var_name, context_binding
        return true if evaluate_dynamic_methods(var_name, resource, methods, person)
      end

      return false
    end

    def evaluate_dynamic_methods(var_name, resource, methods, person)
      methods.each do |name, type|
        next unless resource.respond_to? name

        case type
        when :method then return resource.send name, person
        when :getter then return resource.send(name) == person
        when :collection then return resource.send(name).exists?(person)
        else return false
        end
      end

      # Target didn't respond to any attempts. This would be a problem.
      raise PermitEvaluationError, "Target object ':#{var_name}' evaluated as #{resource.inspect} did not respond to any of the following: #{methods.collect {|n,t| n}.join(', ')}"
    end

    # is_owner - is_owner(), is_owner?(), owner?(), owner, owners.exists()
    # is_manager? - is_manager?(), manager?()
    # has_something - has_something()
    # does_whatever - does_whatever()
    def determine_method_sequence(method)
      method = method.to_s
      names = /^is_([\w\-]+(\?)?)$/.match method
      return [[method, :method]] unless names
      
      # Name ends with question mark
      if names[2] == "?"
        [[names[0], :method], [names[1], :method]]
      else
        [
          [names[0], :method],
          [names[0] + '?', :method],
          [names[1], :getter],
          [names[1] + '?', :method],
          [names[1].pluralize, :collection]
        ]
      end      
    end

    def get_resource(var, context_binding)
      var_name = "@#{var.to_s}"
      if eval(%Q{instance_variables.include? "#{var_name}"}, context_binding)
        eval var_name, context_binding
      else
        raise PermitEvaluationError, "Target resource '#{var_name}' did not exist in the given context."
      end
    end

    def passes_conditionals?(person, context_binding)
      return false unless eval_conditional @if, true, person, context_binding
      return false if eval_conditional @unless, false, person, context_binding
      true
    end

    def eval_conditional(condition, default, person, context_binding)
      if condition
        condition = condition.to_s if Symbol===condition
        return (String===condition ? eval(condition, context_binding) : condition.call(person, context_binding))
      else
        return default
      end
    end

  end

end
