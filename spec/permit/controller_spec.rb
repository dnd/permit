require File.dirname(__FILE__) + '/../spec_helper'

module Permit::Specs
  class EmployeeAdmin < ActiveRecord::Base
  end

  class BaseController < ActionController::Base
    include Permit::ControllerExtensions

    def current_person; end
  end

  class ProjectsController < BaseController
    permit :some_option => true do
      deny :guest, :from => :all
      allow :person, :to => :all
    end

    before_filter :something_after_permit

    def index
      render :text => 'index called'
    end

    def show
      render :text => 'show called'
    end

    def something_after_permit; end

    def access_denied
      render :text => 'guest denied', :status => 401
    end

    #These methods are just to aid in testing
    def pub_authorized?(roles, resource)
      authorized?(roles, resource)
    end

    def pub_allowed?(*args)
      allowed?(*args)
    end

    def pub_denied?(*args)
      denied?(*args)
    end
  end

  class TeamsController < BaseController
    permit :default_access => :allow do
      deny :guest, :from => :index
    end
  end

  class DefinedDenialsController < ActionController::Base
    include Permit::ControllerExtensions

    permit do
      deny :everyone, :from => :all
    end

    def index;end

    def current_person; end

    def access_denied
      render :text => 'base denied message', :status => 401
    end
  end

  ActionController::Routing::Routes.draw do |map|
    map.namespace :permit do |p|
      p.namespace :specs do |s|
        s.resources :projects
        s.resources :defined_denials
      end
    end
  end

  describe ControllerExtensions, :type => :controller do
    controller_name 'permit/specs/projects'

    describe "#permit" do
      it "should create the rules in permit_rules" do
      end

      it "should send any given options to permit_rules" do
        controller.permit_rules.options[:some_option].should be_true
      end

      it "should have the same rules as another instance of the same controller" do
        controller.permit_rules.should be(ProjectsController.new.permit_rules)
      end

      it "should not have the same rules as another controller" do
        teams = TeamsController.new
        teams.permit_rules.action_allow_rules.should have(0).item
        teams.permit_rules.action_deny_rules.should have(1).item
        team_deny_rule = teams.permit_rules.action_deny_rules[:index][0]
        team_deny_rule.roles.should == [:guest]

        controller.permit_rules.action_allow_rules.should have(1).item
        controller.permit_rules.action_deny_rules.should have(1).item

        project_allow_rule = controller.permit_rules.action_allow_rules[:all][0]
        project_allow_rule.roles.should == [:person]

        project_deny_rule = controller.permit_rules.action_deny_rules[:all][0]
        project_deny_rule.roles.should == [:guest]
      end
    end

    describe "checking authorizations" do
      it "should properly call @@permit_rules#permitted? when checking authorizations" do
        guest = Guest.new
        controller.stub!(:current_person).and_return(guest)
        controller.permit_rules.should_receive(:permitted?).with(guest, :show, instance_of(Binding)).and_return(false)
        get :show, :id => 1
      end

      describe "when authorized" do
        it "should call the action" do
          controller.stub!(:current_person).and_return(Person.create :name => 'bob')
          get :index
          response.body.should == 'index called'
        end
      end

      describe "when not authorized" do
        before do
          controller.stub!(:current_person).and_return(Guest.new)
        end

        it "should stop the before_filter chain if not authorized" do
          controller.should_not_receive(:something_after_permit)
          get :index
        end

        it "should not call the action" do
          controller.should_not_receive(:index)
          get :index
        end

        it "should have a 401 status" do
          get :index
          response.status.should == '401 Unauthorized'
        end

        it "should render a 401 error" do
          get :index
          response.body.should == "guest denied"
        end
      end

      describe "getting the authorization subject" do
        it "should use the config value when present" do
          Permit::Config.stub!(:controller_subject_method).and_return(:logged_user)
          controller.should_receive(:logged_user).and_return(Guest.new)
          get :index
        end

        it "should infer the method name from the config person_class" do
          Permit::Config.stub!(:person_class).and_return(Permit::Specs::EmployeeAdmin)
          controller.should_receive(:current_employee_admin).and_return(Guest.new)
          get :index
        end

        it "should default to 'current_person'" do
          Permit::Config.stub!(:controller_subject_method).and_return(nil)
          Permit::Config.stub!(:person_class).and_return(nil)
          controller.should_receive(:current_person).and_return(Guest.new)
          get :index
        end
      end
    end

    describe "helpers" do
      describe "#authorized?" do
        context "for a guest" do
          before {controller.stub!(:current_person).and_return(Guest.new)}

          it "should return false for a guest" do
            controller.pub_authorized?(:some_role, :any).should be_false
          end

          it "should not try to call #authorized? on the guest" do
            controller.current_person.should_not_receive(:authorized?)
          end
        end

        context "for an authenticated person" do
          before do
            @bob = Person.create! :name => 'bob'
            new_authz @bob, :admin

            controller.stub!(:current_person).and_return(@bob)
          end

          it "should properly call #authorized? on the person" do
            @bob.should_receive(:authorized?).with(:admin, :any)
            controller.pub_authorized?(:admin, :any)
          end

          it "should return false if the person is not authorized" do
            controller.pub_authorized?(:monkey_tech, nil).should be_false
          end

          it "should return true if the person is authorized" do
            controller.pub_authorized?(:admin, :any).should be_true
          end
        end
      end

      describe "#allowed?" do
        context "for a rule" do
          it "should properly build the rule" do
            controller.stub!(:current_person).and_return(Guest.new)
            rule = PermitRule.new :admin, :on => :team
            PermitRule.should_receive(:new).with(:admin, hash_including(:on => :team)).and_return(rule)
            controller.pub_allowed?(:admin, :on => :team)
          end

          it "should properly call #matches? on the rule" do
            bob = Person.create! :name => 'bob'
            controller.stub!(:current_person).and_return(bob)
            rule = PermitRule.new :guest
            rule.should_receive(:matches?).with(bob, instance_of(Binding))
            PermitRule.stub!(:new).and_return(rule)
            controller.pub_allowed?(:guest)
          end

          it "should return the result of the rule match" do
            controller.stub!(:current_person).and_return(Guest.new)
            rule = PermitRule.new :guest
            PermitRule.stub!(:new).and_return(rule)

            rule.stub!(:matches?).and_return(true)
            controller.pub_allowed?(:guest).should be_true

            rule.stub!(:matches?).and_return(false)
            controller.pub_allowed?(:guest).should be_false
          end
        end

        context "for an action on the current controller" do
          it "should evaluate the rules for the action on the current controller" do
            guest = Guest.new
            controller.stub!(:current_person).and_return(guest)
            ProjectsController.permit_rules.should_receive(:permitted?).with(guest, :show, instance_of(Binding)).and_return(true)
            controller.pub_allowed?(:action => :show).should be_true
          end
        end

        context "for an action on a different controller" do
          it "should evaluate the rules for the action on the given controller" do
            guest = Guest.new
            controller.stub!(:current_person).and_return(guest)
            TeamsController.permit_rules.should_receive(:permitted?).with(guest, :index, instance_of(Binding)).and_return(true)
            controller.pub_allowed?(:controller => 'permit/specs/teams', :action => :index).should be_true
          end
        end
      end

      describe "#denied?" do
        context "for a rule" do
          it "should properly build the rule" do
            controller.stub!(:current_person).and_return(Guest.new)
            rule = PermitRule.new :admin, :on => :team
            PermitRule.should_receive(:new).with(:admin, hash_including(:on => :team)).and_return(rule)
            controller.pub_denied?(:admin, :on => :team)
          end

          it "should properly call #matches? on the rule" do
            bob = Person.create! :name => 'bob'
            controller.stub!(:current_person).and_return(bob)
            rule = PermitRule.new :guest
            rule.should_receive(:matches?).with(bob, instance_of(Binding))
            PermitRule.stub!(:new).and_return(rule)
            controller.pub_denied?(:guest)
          end

          it "should return the opposite of the rule match" do
            controller.stub!(:current_person).and_return(Guest.new)
            rule = PermitRule.new :guest
            PermitRule.stub!(:new).and_return(rule)

            rule.stub!(:matches?).and_return(true)
            controller.pub_denied?(:guest).should be_false

            rule.stub!(:matches?).and_return(false)
            controller.pub_denied?(:guest).should be_true
          end
        end

        context "for an action on the current controller" do
          it "should evaluate the rules for the action on the current controller" do
            guest = Guest.new
            controller.stub!(:current_person).and_return(guest)
            ProjectsController.permit_rules.should_receive(:permitted?).with(guest, :show, instance_of(Binding)).and_return(true)
            controller.pub_denied?(:action => :show).should be_false
          end
        end

        context "for an action on a different controller" do
          it "should evaluate the rules for the action on the given controller" do
            guest = Guest.new
            controller.stub!(:current_person).and_return(guest)
            TeamsController.permit_rules.should_receive(:permitted?).with(guest, :index, instance_of(Binding)).and_return(true)
            controller.pub_denied?(:controller => 'permit/specs/teams', :action => :index).should be_false
          end
        end
      end
    end

    describe "resetting core models" do
      before {controller.stub!(:current_person).and_return(Guest.new)}

      it "should reset the core models in development mode" do
        # Can't find a good way to test this since development mode needs to be
        # simulated before the controller is loaded.

        #Rails.env.stub!(:development?).and_return(true)
        #Permit::Config.should_receive(:reset_core_models)
        #get :index
      end

      it "should not reset the core models when not in dev mode" do 
        controller.should_not_receive(:reset_permit_core)
        Permit::Config.should_not_receive(:reset_core_models)
        get :index
      end
    end
  end

  describe ControllerExtensions, :type => :controller do
    controller_name 'permit/specs/defined_denials'

    describe "checking authorizations" do
      context "when #access_denied is previously defined in the class" do
        it "should call the class's method" do
          controller.stub!(:current_person).and_return(Guest.new)
          get :index
          response.body.should == 'base denied message'
        end
      end
    end
  end
end
