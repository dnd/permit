require File.dirname(__FILE__) + '/../spec_helper'

module Permit::Specs
  describe "Permit::Models::AuthorizationExtensions#permit_authorization" do
    describe "validations" do
      it "should be invalid without a role" do
        a = Authorization.new
        a.should_not be_valid
        a.should have(1).error_on(:role)
        a.errors[:role].should == "can't be blank"
      end

      it "should be invalid without a person" do
        a = Authorization.new
        a.should_not be_valid
        a.should have(1).error_on(:person)
        a.errors[:person].should == "can't be blank"
      end

      it "should be invalid without a resource if the role requires one" do
        r = Role.new :requires_resource => true
        a = Authorization.new :role => r
        a.should_not be_valid
        a.should have(1).error_on(:resource)
        a.errors[:resource].should == "can't be blank"
      end

      it "should be invalid with a resource if the role doesn't allow one" do
        r = Role.new :authorize_resource => false, :requires_resource => false
        a = Authorization.new :role => r
        a.resource = Project.create :name => "First"

        a.should_not be_valid
        a.should have(1).error_on(:resource)
        a.errors[:resource].should ==  "Specific resources may not be granted for this role."
      end

      it "should allow a resource if the role allows but doesn't require a resource" do
        r = Role.new :authorize_resource => true, :requires_resource => false
        a = Authorization.new :role => r
        a.resource = Project.create :name => "First"

        a.valid?
        a.should have(0).errors_on(:resource)
      end

      it "should allow no resource if the role allows but doesn't require a resource" do
        r = Role.new :authorize_resource => true, :requires_resource => false
        a = Authorization.new :role => r

        a.valid?
        a.should have(0).errors_on(:resource)
      end
      
      it "should be invalid if the person is already authorized for the given role and resource" do
        p = Person.create :name => 'bob'
        r = Role.create :key => :admin, :name => "Admin"
        project = Project.create! :name => "First"
        Authorization.create! :role => r, :person => p, :resource => project

        a = Authorization.new :role => r, :person => p, :resource => project
        a.should_not be_valid
        a.should have(1).error_on(:role)
        a.errors[:role].should == "This person is already authorized for this resource"
      end

      it "should be valid with valid attributes" do
        p = Person.create :name => 'bob'
        r = Role.create :key => :admin, :name => "Admin"
        a = Authorization.new :role => r, :person => p
        a.resource = Project.create :name => "First"

        a.save.should be_true
      end
    end
  end
end
