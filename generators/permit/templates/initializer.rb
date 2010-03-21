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
