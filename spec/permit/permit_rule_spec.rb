require File.dirname(__FILE__) + '/../spec_helper'
include Permit

def allow_rule(options = {})
  PermitRule.new((options.delete(:roles) || :admin), options)
end

def allow_person_rule(options = {})
  options[:roles] = :person
  allow_rule options
end

module Permit::Specs
  describe PermitRule, "initialization" do
    context "of roles" do
      it "should raise an error with no roles" do
        lambda {
          PermitRule.new nil
        }.should raise_error(PermitConfigurationError, "At least one role must be specified.")
      end

      it "should accept one custom role" do
        r = nil
        lambda {r = PermitRule.new :admin}.should_not raise_error
        r.roles.should == [:admin]
      end

      it "should accept multiple custom roles" do
        r = nil
        lambda {r = PermitRule.new [:admin, :member]}.should_not raise_error
        r.roles.should == [:admin, :member]
      end

      it "should accept one builtin role" do
        r = nil
        [:everyone, :person, :guest].each do |role|
          lambda {r = PermitRule.new role}.should_not raise_error
          r.roles.should == [role]
        end
      end

      it "should raise an error with multiple builtin roles" do
        lambda {PermitRule.new [:everyone, :person, :guest]}.should raise_error(PermitConfigurationError, "Only one role may be specified when using :person, :guest, or :everyone") 
      end

      it "should raise an error with mixed builtin and custom roles" do
        lambda {PermitRule.new [:person, :admin]}.should raise_error(PermitConfigurationError, "Only one role may be specified when using :person, :guest, or :everyone") 
      end

      it "should not be modifiable" do
        r = PermitRule.new :person
        lambda {r.roles << :hackyrole}.should raise_error(TypeError)
      end
    end

    context "of resource" do
      it "should raise an error if both :of and :on are given" do
        lambda { 
          allow_rule :of => :thing, :on => :something
        }.should raise_error(PermitConfigurationError, "Either :of or :on may be specified, but not both.") 
      end

      it "should store accept the resource through :of" do
        r = allow_rule :of => :team
        r.target_var.should == :team
      end

      it "should accept the resource through :on" do
        r = allow_rule :on => :project
        r.target_var.should == :project
      end

      it "should not be modifiable" do
        r = allow_rule :on => :project
        lambda {r.target_var = :other}.should raise_error(NoMethodError)
      end
    end

    context "of method" do
      it "should raise an error if both :who and :that are given" do
        lambda {
          allow_person_rule :who => :is_member, :that => :is_owner, :on => :team
        }.should raise_error(PermitConfigurationError, "Either :who or :that may be specified, but not both.") 
      end

      it "should not be modifiable" do
        r = allow_person_rule :who => :is_member, :of => :team
        lambda { r.method = :monkey }.should raise_error(NoMethodError)
      end

      it "should raise an error if method is given for a non :person role" do
        [:everyone, :guest, :manager].each do |role|
          [:who, :that].each do |key|
            lambda {
              allow_rule :roles => role, key => :something, :on => :team
            }.should raise_error(PermitConfigurationError, "The :who and :that options are only valid for the :person role.") 
          end
        end
      end

      context "when given for :person role" do
        it "should raise an error if the resource is not specified" do
          lambda {
            allow_person_rule :who => :is_member
          }.should raise_error(PermitConfigurationError, "When :who or :that is specified a corresponding :of or :on must be given") 
        end

        it "should accept the resource and method" do
          r = allow_person_rule :who => :is_member, :of => :team
          r.target_var.should == :team
          r.method.should == :is_member
        end
      end
    end

    context "of :if condition" do
      it "should allow an :if condition" do
        r = allow_rule :if => :some_method
        r.if.should == :some_method
      end

      it "should not be modifiable" do
        r = allow_rule :if => :something
        lambda {r.if = :other}.should raise_error(NoMethodError)
      end
    end

    context "of :unless condition" do
      it "should allow an :unless condition" do
        r = allow_rule :unless => :something_happened
        r.unless.should == :something_happened
      end

      it "should not be modifiable" do
        r = allow_rule :unless=> :something
        lambda {r.unless = :other}.should raise_error(NoMethodError)
      end
    end

  end

  describe PermitRule, "#matches?" do
    context "for the :everyone role" do
      it "should match for a guest" do
        r = allow_rule :roles => :everyone
        r.matches?(Guest.new, binding).should be_true
      end

      it "should match for a non-guest" do
        p = Person.create :name => 'bob'
        r = allow_rule :roles => :everyone
        r.matches?(p, binding).should be_true
      end

      it "should allow any action for :all" do
        r = allow_rule :roles => :everyone
        r.matches?(Guest.new, binding).should be_true
        r.matches?(Guest.new, binding).should be_true
        r.matches?(Guest.new, binding).should be_true
      end
    end

    context "for the :guest role" do
      it "should match for a guest" do
        r = allow_rule :roles => :guest
        r.matches?(Guest.new, binding).should be_true
      end

      it "should not match for a non-guest" do
        p = Person.create :name => 'bob'
        r = allow_rule :roles => :guest
        r.matches?(p, binding).should be_false
      end
    end

    context "for the :person role" do
      before do
        @team = Team.new
        @person = Person.create :name => 'bob'
      end

      context "with no target to evaluate against" do
        it "should not match for a guest" do
          r = allow_person_rule
          r.matches?(Guest.new, binding).should be_false
        end

        it "should match for a non-guest" do
          r = allow_person_rule
          r.matches?(@person, binding).should be_true
        end
      end

      context "when the target resource does not exist" do
        it "should raise an error" do
          rule = allow_person_rule :who => :is_owner, :on => :oops
          lambda {
            rule.matches? @person, binding
          }.should raise_error(PermitEvaluationError, "Target resource '@oops' did not exist in the given context.")
        end
      end

      context "using an is_* method" do
        before {@rule = allow_person_rule :who => :is_owner, :on => :team}

        context "attempting #is_owner" do
          it "should call #is_owner on the resource" do
            @team.should_receive(:is_owner).with(@person).and_return(true)
            @rule.matches?(@person, binding)
          end

          it "should return the result of the resource call" do
            @team.stub!(:is_owner).and_return(true)
            @rule.matches?(@person, binding).should be_true
            @team.stub!(:is_owner).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end
        end

        context "attempting #is_owner?" do
          it "should call #is_owner? on the resource" do
            @team.should_receive(:is_owner?).with(@person).and_return(true)
            @rule.matches?(@person, binding).should be_true
          end

          it "should return the result of the resource call" do
            @team.stub!(:is_owner?).and_return(true)
            @rule.matches?(@person, binding).should be_true
            @team.stub!(:is_owner?).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end
        end

        context "attempting #owner?" do
          it "should call #owner? on the resource" do
            @team.should_receive(:owner?).with(@person).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end

          it "should return the result of the resource call" do
            @team.stub!(:owner?).and_return(true)
            @rule.matches?(@person, binding).should be_true
            @team.stub!(:owner?).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end
        end

        context "attempting #owner" do
          it "should call #owner on the resource" do
            @team.should_receive(:owner).and_return(@person)
            @rule.matches?(@person, binding).should be_true
          end

          it "should return the result of the comparison of the resource call with the current person" do
            @team.stub!(:owner).and_return(@person)
            @rule.matches?(@person, binding).should be_true
            jim = Person.create :name => 'jim'
            @team.stub!(:owner).and_return(jim)
            @rule.matches?(@person, binding).should be_false
          end
        end

        context "attempting #owners.exists?" do
          it "should call #owners.exists? on the resource" do
            owners = mock("owners")
            owners.should_receive(:exists?).with(@person).and_return(true)
            @team.stub!(:owners).and_return(owners)
            @rule.matches?(@person, binding).should be_true
          end

          it "should return the result of the resource call" do
            owners = mock("owners")
            @team.stub!(:owners).and_return(owners)
            owners.stub!(:exists?).and_return(true)
            @rule.matches?(@person, binding).should be_true
            owners.stub!(:exists?).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end
        end

        it "should raise an error if none of the attempted calls responded" do
          @team.stub!(:respond_to?).and_return(false)
          lambda { 
            @rule.matches?(@person, binding)
          }.should raise_error(PermitEvaluationError,  "Target object ':team' evaluated as #{@team.inspect} did not respond to any of the following: is_owner, is_owner?, owner, owner?, owners")
        end
      end

      context "using an is_*? method" do
        before {@rule = allow_person_rule :who => :is_manager?, :on => :team}

        context "attempting #is_manager?" do
          it "should call #is_manager? on the resource" do
            @team.should_receive(:is_manager?).with(@person).and_return(true)
            @rule.matches?(@person, binding)
          end

          it "should return the result from the resource call" do
            @team.stub!(:is_manager?).and_return(true)
            @rule.matches?(@person, binding).should be_true
            @team.stub!(:is_manager?).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end

          it "should not call #manager? if resource responds to #is_manager?" do
            @team.stub!(:is_manager?).and_return(true)
            @team.should_not_receive(:manager?)
            @rule.matches?(@person, binding)
          end

        end

        context "attempting #manager?" do
          it "should call #manager? on the resource" do
            @team.should_receive(:manager?).with(@person).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end

          it "should return the result from the resource call" do
            @team.stub!(:manager?).and_return(true)
            @rule.matches?(@person, binding).should be_true
            @team.stub!(:manager?).and_return(false)
            @rule.matches?(@person, binding).should be_false
          end
        end

        it "should raise an error if none of the attempted calls responded" do
          @team.stub!(:respond_to?).and_return(false)
          lambda { 
            @rule.matches?(@person, binding)
          }.should raise_error(PermitEvaluationError,  "Target object ':team' evaluated as #{@team.inspect} did not respond to any of the following: is_manager?, manager?")
        end
      end

      context "using any other method" do
        before {@rule = allow_person_rule :who => :has_permission, :on => :team}
        it "should call the method on the resource" do
          @team.should_receive(:has_permission).with(@person)
          @rule.matches?(@person, binding)
        end

        it "should raise an error if the attempted call did not respond" do
          @team.stub!(:respond_to?).and_return(false)
          lambda { 
            @rule.matches?(@person, binding)
          }.should raise_error(PermitEvaluationError,  "Target object ':team' evaluated as #{@team.inspect} did not respond to any of the following: has_permission")
        end
      end

    end

    context "for a named authorization" do
      before do
        @bob = Person.create :name => "bob"
        @tom = Person.create :name => "tom"
        @hotness = Project.create(:name => "hotness")
        @maintenance = Project.create(:name => "maintenance")
        Role.create :key => :site_admin, :name => 'site admin', :authorize_resource => false, :requires_resource => false
        new_authz @bob, :site_admin, nil
        new_authz @bob, :admin, @maintenance
        new_authz @bob, :developer, @maintenance
        new_authz @bob, :team_lead, @hotness

        new_authz @tom, :admin, @hotness
      end

      it "should return false for a guest" do
        r = PermitRule.new :admin
        r.matches?(Guest.new, binding).should be_false
      end

      context "with a resource" do
        it "should return true if the person is authorized for the role and resource" do
          r = allow_rule :roles => :admin, :of => :maintenance
          r.matches?(@bob, binding).should be_true
        end

        it "should return false if the person is not authorized for the role and resource" do
          r = allow_rule :roles => :monkey_tech, :of => :maintenance
          r.matches?(@bob, binding).should be_false
        end
        
        context "that does not exist" do
          it "should raise an error" do
            rule = allow_rule :roles => :site_admin, :of => :oops
            lambda {
              rule.matches? @bob, binding
            }.should raise_error(PermitEvaluationError, "Target resource '@oops' did not exist in the given context.")
          end
        end
      end

      context "without a resource" do
        it "should return true if the person is authorized for the role" do
          r = allow_rule :roles => :site_admin
          r.matches?(@bob, binding).should be_true
        end

        it "should return false if the person is not authorized for the role" do
          r = allow_rule :roles => :admin
          r.matches?(@bob, binding).should be_false
        end
      end

      context "with any resource" do
        it "should return true if the person is authorized for the role and a resource" do
          r = allow_rule :roles => :admin, :of => :any
          r.matches?(@bob, binding).should be_true
        end

        it "should return false if the person is not authorized for the role and a resource" do
          r = allow_rule :roles => :developer, :of => :any
          r.matches?(@tom, binding).should be_false
        end
      end
    end

    context "for multiple named authorizations" do
      before do
        @bob = Person.create :name => "bob"
        @tom = Person.create :name => "tom"
        @hotness = Project.create(:name => "hotness")
        @maintenance = Project.create(:name => "maintenance")
        Role.create :key => :site_admin, :name => 'site admin', :authorize_resource => false, :requires_resource => false
        new_authz @bob, :site_admin, nil
        new_authz @bob, :admin, @maintenance
        new_authz @bob, :developer, @maintenance
        new_authz @bob, :team_lead, @hotness

        new_authz @tom, :admin, @hotness
      end

      context "with a resource" do
        it "should return true if the person is authorized for any of the roles and resource" do
          r = allow_rule :roles => [:admin, :team_lead], :of => :maintenance
          r.matches?(@bob, binding).should be_true
        end

        it "should return false if the person is not authorized for any of the roles and resource" do
          r = allow_rule :roles => [:site_admin, :monkey_tech], :of => :maintenance
          r.matches?(@bob, binding).should be_false
        end

        context "that does not exist" do
          it "should raise an error" do
            rule = allow_rule :roles => [:site_admin, :team_lead], :of => :oops
            lambda {
              rule.matches? @bob, binding
            }.should raise_error(PermitEvaluationError, "Target resource '@oops' did not exist in the given context.")
          end
        end
      end

      context "without a resource" do
        it "should return true if the person is authorized for any of the roles" do
          r = allow_rule :roles => [:site_admin, :team_lead]
          r.matches?(@bob, binding).should be_true
        end

        it "should return false if the person is not authorized for any of the roles" do
          r = allow_rule :roles => [:admin, :team_lead]
          r.matches?(@bob, binding).should be_false
        end
      end

      context "with any resource" do
        it "should return true if the person is authorized for any of the roles and a resource" do
          r = allow_rule :roles => [:admin, :team_lead], :of => :any
          r.matches?(@bob, binding).should be_true
        end

        it "should return false if the person is not authorized for any of the roles and a resource" do
          r = allow_rule :roles => [:developer, :site_admin], :of => :any
          r.matches?(@tom, binding).should be_false
        end
      end
    end
  end
end
