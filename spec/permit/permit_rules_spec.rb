require File.dirname(__FILE__) + '/../spec_helper'
include Permit

module Permit::Specs
  describe PermitRules do
    describe "#initialize" do
      it "should have an empty hash for allow rules" do
        rules = PermitRules.new nil
        rules.action_allow_rules.should == {}
      end

      it "should have an empty hash for deny rules" do
        rules = PermitRules.new nil
        rules.action_deny_rules.should == {}
      end

      it "should set the logger" do
        rules = PermitRules.new "some logger"
        rules.logger.should == "some logger"
      end

      it "should set the options" do
        rules = PermitRules.new nil, :default_access => :allow
        rules.options[:default_access].should == :allow
      end
    end

    describe "#allow" do
      before do
        @rules = PermitRules.new nil
      end

      it "should raise an error with no action" do
        lambda {
          @rules.allow :admin
        }.should raise_error(PermitConfigurationError, "At least one action must be given to authorize access for.") 

        lambda {
          @rules.allow :admin, :to => nil
        }.should raise_error(PermitConfigurationError, "At least one action must be given to authorize access for.") 
      end

      it "should raise an error if multiple actions are given with :all" do
        lambda {
          @rules.allow :admin, :to => [:all, :show]
        }.should raise_error(PermitConfigurationError, "If :all is specified for :to/:from then no other actions may be given.") 
      end

      it "should accept one action" do
        r = @rules.allow :admin, :to => :show
        @rules.action_allow_rules.should have(1).item
        @rules.action_allow_rules[:show].should have(1).item
        @rules.action_allow_rules[:show][0].should == r
      end

      it "should accept multiple actions" do
        r = @rules.allow :admin, :to => [:show, :index]
        @rules.action_allow_rules.should have(2).items
        @rules.action_allow_rules[:show].should have(1).item
        @rules.action_allow_rules[:show][0].should == r
        @rules.action_allow_rules[:index].should have(1).item
        @rules.action_allow_rules[:index][0].should == r
      end

      it "should expand alias :read" do
        r = @rules.allow :admin, :to => :read
        @rules.action_allow_rules[:show].should have(1).item
        @rules.action_allow_rules[:show][0].should == r
        @rules.action_allow_rules[:index].should have(1).item
        @rules.action_allow_rules[:index][0].should == r
      end

      it "should expand aliases" do
        {
          :create => [:new, :create], 
          :update => [:edit, :update], 
          :destroy => [:delete, :destroy],
          :read => [:index, :show], 
          :write => [:new, :create, :edit, :update]
        }.each do |alias_action, actions|
          rules = PermitRules.new nil
          r = rules.allow :admin, :to => alias_action
          actions.each do |action|
            rules.action_allow_rules[action].should have(1).item
            rules.action_allow_rules[action][0].should == r
          end
        end
      end

      it "should not have multiple entries for the same action" do
        r = @rules.allow :admin, :to => [:show, :index, :show]
        @rules.action_allow_rules[:show].should have(1).item
        @rules.action_allow_rules[:show][0].should == r
        @rules.action_allow_rules[:index].should have(1).item
        @rules.action_allow_rules[:index][0].should == r
      end

      it "should not have nil actions" do
        r = @rules.allow :admin, :to => [:new, nil]
        @rules.action_allow_rules[:new].should have(1).item
        @rules.action_allow_rules[:new][0].should == r
      end
    end

    describe "#deny" do
      before do
        @rules = PermitRules.new nil
      end

      it "should raise an error with no action" do
        lambda {
          @rules.deny :admin
        }.should raise_error(PermitConfigurationError, "At least one action must be given to authorize access for.") 

        lambda {
          @rules.deny :admin, :from => nil
        }.should raise_error(PermitConfigurationError, "At least one action must be given to authorize access for.") 
      end

      it "should raise an error if multiple actions are given with :all" do
        lambda {
          @rules.deny :admin, :from => [:all, :show]
        }.should raise_error(PermitConfigurationError, "If :all is specified for :to/:from then no other actions may be given.") 
      end

      it "should accept one action" do
        r = @rules.deny :admin, :from => :show
        @rules.action_deny_rules.should have(1).item
        @rules.action_deny_rules[:show].should have(1).item
        @rules.action_deny_rules[:show][0].should == r
      end

      it "should accept multiple actions" do
        r = @rules.deny :admin, :from => [:show, :index]
        @rules.action_deny_rules.should have(2).items
        @rules.action_deny_rules[:show].should have(1).item
        @rules.action_deny_rules[:show][0].should == r
        @rules.action_deny_rules[:index].should have(1).item
        @rules.action_deny_rules[:index][0].should == r
      end

      it "should expand alias :read" do
        r = @rules.deny :admin, :from => :read
        @rules.action_deny_rules[:show].should have(1).item
        @rules.action_deny_rules[:show][0].should == r
        @rules.action_deny_rules[:index].should have(1).item
        @rules.action_deny_rules[:index][0].should == r
      end

      it "should expand aliases" do
        {
          :create => [:new, :create], 
          :update => [:edit, :update], 
          :destroy => [:delete, :destroy],
          :read => [:index, :show], 
          :write => [:new, :create, :edit, :update]
        }.each do |alias_action, actions|
          rules = PermitRules.new nil
          r = rules.deny :admin, :from => alias_action
          actions.each do |action|
            rules.action_deny_rules[action].should have(1).item
            rules.action_deny_rules[action][0].should == r
          end
        end
      end

      it "should not have multiple entries for the same action" do
        r = @rules.deny :admin, :from => [:show, :index, :show]
        @rules.action_deny_rules[:show].should have(1).item
        @rules.action_deny_rules[:show][0].should == r
        @rules.action_deny_rules[:index].should have(1).item
        @rules.action_deny_rules[:index][0].should == r
      end

      it "should not have nil actions" do
        r = @rules.deny :admin, :from => [:new, nil]
        @rules.action_deny_rules[:new].should have(1).item
        @rules.action_deny_rules[:new][0].should == r
      end
    end

    describe "#permitted?" do
      before do
        @logger = mock("logger")
        @logger.stub!(:info).and_return(nil)
      end

      context "for deny rules" do
        before do
          @rules = PermitRules.new @logger, :default_access => :allow
        end

        describe "when a person matches an :all actions deny rule" do
          it "should return false" do
            @rules.deny :everyone, :from => :delete
            @rules.deny :everyone, :from => :all
            @rules.permitted?(Guest.new, :delete, binding).should be_false
          end
        end

        describe "when a person matches a deny rule" do
          it "should return false" do
            @rules.deny :everyone, :from => :show
            @rules.permitted?(Guest.new, :show, binding).should be_false
          end
        end

        describe "when a person matches a deny and an allow rule" do
          it "should return false" do
            @rules.allow :everyone, :to => :create
            @rules.deny :everyone, :from => :create
            @rules.permitted?(Guest.new, :create, binding).should be_false
          end
        end
      end

      context "for allow rules" do
        before do
          @rules = PermitRules.new @logger
        end

        describe "when a person matches an :all actions allow rule" do
          it "should return true" do
            @rules.allow :everyone, :to => :all
            @rules.permitted?(Guest.new, :index, binding).should be_true
          end
        end

        describe "when a person matches an allow rule" do
          it "should return true" do
            @rules.allow :everyone, :to => :new
            @rules.permitted?(Guest.new, :new, binding).should be_true
          end
        end
      end


      describe "when a person doesn't match any rules" do
        before {@default = Permit::Config.default_access}

        describe "and the :default_access option is not set" do
          it "should return false if Permit::Config#default_access is not set to :allow" do
            Permit::Config.default_access = :deny
            rules = PermitRules.new @logger
            rules.permitted?(Guest.new, :show, binding).should be_false
          end

          it "should return true if Permit::Config#default_access is set to :allow" do
            Permit::Config.default_access = :allow
            rules = PermitRules.new @logger
            rules.permitted?(Guest.new, :show, binding).should be_true
          end
        end

        describe "and the :default_access option is set" do
          it "should return true if the option is set to :allow" do
            Permit::Config.default_access = :deny
            rules = PermitRules.new @logger, :default_access => :allow
            rules.permitted?(Guest.new, :index, binding).should be_true
          end

          it "should return false if the option is not set to :allow" do
            Permit::Config.default_access = :allow
            rules = PermitRules.new @logger, :default_access => :deny
            rules.permitted?(Guest.new, :index, binding).should be_false
          end
        end

        after {Permit::Config.default_access = @default}
      end
    end
  end
end
