# models include Permit::Specs so that they will prefer spec models to 
# identically named models in main app.
module Permit::Specs
  class Person < ActiveRecord::Base
    include Permit::Specs

    has_and_belongs_to_many :teams

    def guest?
      new_record?
    end
  end

  class Guest
    def guest?
      true
    end
  end

  class Role < ActiveRecord::Base
    include Permit::Specs

  end

  class Authorization < ActiveRecord::Base
    include Permit::Specs
  end

  class Project < ActiveRecord::Base
    include Permit::Specs
    permit_authorizable
  end

  class Team < ActiveRecord::Base
    include Permit::Specs
    permit_authorizable
  end
end
