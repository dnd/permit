# Sets up the core models to be used for authorizations, people, and roles. This 
# call is only required if you are using named authorizations, and may only be 
# called once. If you are not using named authorizations you may leave this 
# commented out.
<%if options[:setup_named_roles] -%>
Permit::Config.set_core_models(<%=authorization_class%>, <%=person_class%>, <%=role_class%>)
<%else -%>
# Permit.Config.set_core_models(Authorization, Person, Role)
<%end -%>

# Controls the default response given by PermitRules#permitted? when no rules 
# match. To automatically allow access if no rules match, set this to :allow. 
# Default is :deny.
# Permit::Config.default_access = :deny

# You can modify the action_aliases hash to add your own aliases to be used for 
# expansion by PermitRules. The hash key is a Symbol for the action to be 
# expanded, and an array of Symbols representing the actions to expand it into. 
# Alias expansion is non-rescursive. The defaults are:
# {
#    :create => [:new, :create], 
#    :update => [:edit, :update], 
#    :destroy => [:delete, :destroy],
#    :read => [:index, :show], 
#    :write => [:new, :create, :edit, :update]
#  }
# Permit::Config.action_aliases
