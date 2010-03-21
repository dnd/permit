require File.dirname(__FILE__) + '/../spec_helper'

module Permit::Specs
  describe "Permit::Models::Role#permit_role" do
    describe "validations" do
      it "should be invalid without a key" do
        r = Role.new
        r.should_not be_valid
        r.should have(1).error_on(:key)
        r.errors[:key].should == "can't be blank"
      end

      it "should be invalid with a non-unique key" do
        Role.create :key => :test_role, :name => 'Test Role'
        r = Role.new :key => 'test_role'
        r.should_not be_valid
        r.should have(1).error_on(:key)
        r.errors[:key].should == "has already been taken"
      end

      it "should be invalid without a name" do
        r = Role.new
        r.should_not be_valid
        r.should have(1).error_on(:name)
        r.errors[:name].should == "can't be blank"
      end

      it "should be invalid if it requires a resource but doesn't allow resources" do
        r = Role.new 
        r.authorize_resource = false
        r.requires_resource = true
        r.should_not be_valid
        r.should have(1).error_on(:requires_resource)
        r.errors[:requires_resource].should == "cannot be true if authorize_resource is false"
      end

      it "should be valid with valid attributes" do
        r = Role.new
        r.key = :project_admin
        r.name = "Project Administrator"
        r.should be_valid
      end
    end

    describe "resource requirement" do
      it "should default authorize_resource to true" do
        r = Role.new
        r.authorize_resource.should be_true
      end

      it "should default requires_resource to true" do
        r = Role.new 
        r.requires_resource.should be_true
      end
    end

    context "created instance methods" do
      describe "setting the key" do
        it "should convert the key to lower-case" do
          r = Role.new
          r.key = "Some_Role!"
          r.key.should == "some_role!"
        end

        it "should convert the key from a symbol to a string" do
          r = Role.new
          r.key = :symbol_role
          r.key.should == "symbol_role"
        end

        it "should not fail when given nil" do
          r = Role.new :key => 'bob'
          r.key = nil
          r.key.should be_nil
        end
      end

      
      context "for finding authorizations for a given resource" do
        before do
          @bob = Person.create :name => "bob"
          @tom = Person.create :name => "tom"
          @hotness = Project.create(:name => "hotness")
          @maintenance = Project.create(:name => "maintenance")
          Role.create :key => :site_admin, :name => 'site admin', :authorize_resource => false, :requires_resource => false
          @admin = Role.create :key => 'admin', :name => 'admin'
          new_authz @bob, :site_admin, nil
          new_authz @bob, :developer, @maintenance
          new_authz @bob, :team_lead, @hotness
          @bob.authorize @admin, @maintenance

          @tom.authorize @admin, @hotness
        end

        it "#authorizations.people_for should return the people authorized for the resource on the current role" do
          @jack = Person.create :name => 'jack'
          @jack.authorize @admin, @maintenance
          people = @admin.authorizations.people_for @maintenance
          people.should have(2).items
          people[0].should == @bob
          people[1].should == @jack
        end

        it "#authorizations.for should return the authorizations the current role has for the resource" do
          authz = @admin.authorizations.for @maintenance
          authz.should have(1).items
          authz[0].role.key.should == 'admin'
          authz[0].person.should == @bob
          authz[0].resource.should == @maintenance
        end

        it "#authorizations should have all authorizations that apply to the current role" do
          @admin.authorizations.should have(2).items
          @admin.authorizations[0].person.should == @bob
          @admin.authorizations[1].person.should == @tom
        end
      end
    end

  end
end
