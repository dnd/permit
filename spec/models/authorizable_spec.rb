require File.dirname(__FILE__) + '/../spec_helper'

module Permit::Specs
  describe "Permit::Models::Authorizable#permit_authorizable" do
    describe "defined method self#resource_type" do
      it "should return the db resource_type value" do
        Project.resource_type.should == 'Permit::Specs::Project'
      end
    end

    context "created instance methods" do
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

      context "authorizations" do
        it "should have all authorizations that apply to the current resource" do
          @hotness.should have(2).authorizations
          @hotness.authorizations[0].person.should == @bob
          @hotness.authorizations[0].role.key.should == 'team_lead'
          @hotness.authorizations[1].person.should == @tom
          @hotness.authorizations[1].role.key.should == 'admin'
        end
      end
      
      context "for finding authorizations for given roles" do
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

        it "#authorizations.people_as should return the people as the roles for the current resource" do
          @jack = Person.create :name => 'jack'
          @jack.authorize :admin, @maintenance
          people = @maintenance.authorizations.people_as :admin
          people.should have(2).items
          people[0].should == @bob
          people[1].should == @jack
        end

        it "#authorizations.people_as should not contain duplicates" do
          people = @maintenance.authorizations.people_as [:admin, :developer]
          people.should have(1).item
          people[0].should == @bob
        end

        it "#authorizations.as should return the authorizations for given roles on the current resource" do
          authz = @maintenance.authorizations.as [:admin, :developer]
          authz.should have(2).items
          authz[0].person.should == @bob
          authz[0].role.key.should == 'admin'
          authz[1].person.should == @bob
          authz[1].role.key.should == 'developer'

        end
      end
    end
  end
end
