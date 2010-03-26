require File.dirname(__FILE__) + '/../spec_helper'

module Permit::Specs
  class User < ActiveRecord::Base; end
  class Entitlement < ActiveRecord::Base; end
  class Job < ActiveRecord::Base; end

  describe "Alternate core models" do
    before :all do
      @auth = Permit::Config.authorization_class
      @person = Permit::Config.person_class
      @role = Permit::Config.role_class

      Permit::Config.set_core_models(Permit::Specs::Entitlement, Permit::Specs::User, Permit::Specs::Job)
    end
    
    before do
      @sam = User.create! :name => 'sam'
      @superapp = Project.create! :name => 'superapp'
      @lameapp = Project.create! :name => 'lameapp'
      @dev = Job.create! :key => :developer, :name => 'developer'
      @tester = Job.create! :key => :tester, :name => 'tester'

      @sam.authorize [@dev, @tester], @superapp
      @sam.authorize @dev, @lameapp
    end

    it "subject model should have an entitlements association" do
      @sam.should have(3).entitlements
    end

    it "role model should have an entitlements association" do
      @dev.should have(2).entitlements
    end

    describe "entitlements association" do
      it "should have a users_as method" do
        @dev.entitlements.users_as(@dev).should have(1).item
      end

      it "should have a users_for method" do
        @dev.entitlements.users_for(@superapp).should have(1).item
      end

      it "should have a jobs_for method" do
        @sam.entitlements.jobs_for(@superapp).should have(2).item
      end
    end
    
    after :all do
      Permit::Config.set_core_models(@auth, @person, @role)
    end
  end
end
