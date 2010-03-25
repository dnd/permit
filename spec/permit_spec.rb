require File.dirname(__FILE__) + '/spec_helper'

describe Permit::Config do
  describe "defaults" do
    it "controller_subject_method should default to nil" do
      Permit::Config.controller_subject_method.should be_nil
    end

    it "default_access should be :deny" do
      Permit::Config.default_access.should == :deny
    end
  end

  describe "#set_core_models" do
    before :all do
      @auth = Permit::Config.authorization_class
      @person = Permit::Config.person_class
      @role = Permit::Config.role_class
    end

    it "should set the class variables" do
      Permit::Config.set_core_models(Permit::Specs::Authorization, Permit::Specs::Person, Permit::Specs::Role)
      Permit::Config.authorization_class.should be(Permit::Specs::Authorization)
      Permit::Config.person_class.should be(Permit::Specs::Person)
      Permit::Config.role_class.should be(Permit::Specs::Role)
    end

    it "should setup the permit_* methods on the models" do
      Permit::Specs::Authorization.should_receive(:permit_authorization)
      Permit::Specs::Person.should_receive(:permit_person)
      Permit::Specs::Role.should_receive(:permit_role)
      Permit::Config.set_core_models(Permit::Specs::Authorization, Permit::Specs::Person, Permit::Specs::Role)
    end

    after :all do
      Permit::Config.set_core_models(@auth, @person, @role)
    end
  end

  describe "#reset_core_models" do
    before :all do
      @auth = Permit::Config.authorization_class
      @person = Permit::Config.person_class
      @role = Permit::Config.role_class
    end

    it "should reset the core model classes" do
      Object.should_receive(:const_get).with("Permit::Specs::Authorization").and_return(Permit::Specs::Authorization)
      Object.should_receive(:const_get).with("Permit::Specs::Person").and_return(Permit::Specs::Person)
      Object.should_receive(:const_get).with("Permit::Specs::Role").and_return(Permit::Specs::Role)
      Permit::Config.reset_core_models
    end

    after :all do
      Permit::Config.set_core_models(@auth, @person, @role)
    end
  end
end
