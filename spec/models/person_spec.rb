require File.dirname(__FILE__) + '/../spec_helper'

module Permit::Specs
  describe "Permit::Models::Extensions::permit_person" do
    
    context "created instance methods" do
      it "#authorizations should have all of the person's current authorizations" do

      end

      context "for checking authorizations" do
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

        context "#authorized?" do
          it "should return true if the person has any of the roles for the resource" do
            @bob.should be_authorized(:admin, @maintenance)
          end

          it "should return true if the person has any of the resources for the passed in Role object" do
            r = Role.find_by_key 'admin'
            @bob.should be_authorized(r, @maintenance)
          end

          it "should return false if the person does not have any of the roles for the resource" do
            @bob.should_not be_authorized(:admin, @hotness)
          end

          it "should return false for a role that doesn't exist" do
            @bob.should_not be_authorized(:lead_monkey_tech, @maintenance)
          end

          it "should return true if the person has a nil resource authorization for a role" do
            @bob.should be_authorized(:site_admin, nil)
          end
        end

        context "#authorized_all?" do
          it "should return true if the person matches all of the roles for the resource" do
            @bob.should be_authorized_all([:admin, :developer], @maintenance)
          end

          it "should return true if the person matches all of the roles for the resource when a Role object is passed" do
            r = Role.find_by_key 'developer'
            @bob.should be_authorized_all([r, :admin], @maintenance)
          end

          it "should return false if the person does not match all of the roles for the resource" do
            @tom.should_not be_authorized_all([:admin, :team_lead], @hotness)
          end

          it "should return false if one of the roles does not exist" do
            @tom.should_not be_authorized_all([:admin, :slinky_analyst], @hotness)
          end
        end
      end

      context "#authorize" do
        before do
          @sam = Person.create! :name => 'sam'
          @superapp = Project.create! :name => 'superapp'
          @dev = role(:developer)
          @tester = role(:tester)
        end

        it "should authorize the person for all of the given roles" do
          @sam.authorize([:developer, :tester], @superapp)
          @sam.should have(2).authorizations
          @sam.authorizations[0].role.key.should == 'developer'
          @sam.authorizations[1].role.key.should == 'tester'
        end

        it "should authorize the person if given a role object" do
          @sam.authorize([:developer, @tester], @superapp)
          @sam.should have(2).authorizations
          @sam.authorizations[0].role.key.should == 'developer'
          @sam.authorizations[1].role.key.should == 'tester'
        end

        it "should authorize a person for a nil resource" do
          @noresource = Role.create :key => 'noresource', :name => 'noresource', :requires_resource => false, :authorize_resource => false
          @sam.authorize(@noresource, nil)
          @sam.should have(1).authorization
        end

        it "should not duplicate an existing authorization for a person" do
          @sam.authorize(:developer, @superapp)
          @sam.authorize(:developer, @superapp)
          @sam.should have(1).authorization
        end

        it "should raise an error if the authorization is invalid" do
          lambda {
            @sam.authorize(:chief_donkey_inspector, @superapp)
          }.should raise_error(ActiveRecord::RecordInvalid, "Validation failed: Role can't be blank")
        end

        it "should return true if authorization is successful" do
          @sam.authorize(:tester, @superapp).should be_true
        end

        it "should return true even if there are no authorizations to grant" do
          @sam.authorize(:tester, @superapp)
          @sam.authorize(:tester, @superapp).should be_true
        end

        it "should perform the authorizations in a transaction" do
          # TODO: Find a way to spec. Can't seem to be done with sqlite because 
          # of nested transactions not being allowed?
        end
      end

      context "revocations" do
        before do
          @sam = Person.create! :name => 'sam'
          @superapp = Project.create! :name => 'superapp'
          @lameapp = Project.create! :name => 'lameapp'
          @dev = role(:developer)
          @tester = role(:tester)

          @sam.authorize [@dev, @tester], @superapp
          @sam.authorize @dev, @lameapp
        end

        shared_examples_for "all revocations" do
          it "should revoke all of the given roles on the given resource from the current person" do
            @sam.send @revoke_method, [:developer, :tester], @superapp
            @sam.should have(1).authorization
            @sam.authorizations[0].resource.should == @lameapp
          end

          it "should revoke an authorization when given a role object" do
            @sam.send @revoke_method, [@dev, @tester], @superapp
            @sam.should have(1).authorization
            @sam.authorizations[0].resource.should == @lameapp
          end

          it "should not revoke an identical authorization for another person" do
            @bob = Person.create! :name => 'bob'
            @bob.authorize :developer, @superapp

            @sam.send @revoke_method, :developer, @superapp
            @bob.should have(1).authorization
          end

          it "should revoke an authorization with a nil resource" do 
            @noresource = Role.create :key => 'noresource', :name => 'noresource', :requires_resource => false, :authorize_resource => false
            @sam.authorize(@noresource, nil)

            @sam.send @revoke_method, :noresource, nil
            @sam.should_not be_authorized(:noresource, nil)
          end
          
          it "should raise an error if a revocation fails" do
            Authorization.stub!(@ar_remove_method).and_raise(ActiveRecord::ActiveRecordError)
            lambda {
              @sam.send @revoke_method, :developer, @superapp
            }.should raise_error(ActiveRecord::ActiveRecordError)
          end

          it "should perform revocations in a transaction" do
            # TODO: Find a way to spec. Can't seem to be done with sqlite 
            # because of nested transactions not being allowed?
          end

        end

        context "#revoke" do
          before do
            @revoke_method = :revoke
            @ar_remove_method = :destroy_all
          end

          it_should_behave_like "all revocations"

          it "should return the revoked roles" do
            revoked = @sam.revoke([:developer, :tester], @superapp)
            revoked.size.should == 2
            revoked[0].resource.should == @superapp
            revoked[0].role.should == @dev
            revoked[1].resource.should == @superapp
            revoked[1].role.should == @tester
          end
        end

        context "#revoke!" do
          before do
            @revoke_method = :revoke!
            @ar_remove_method = :delete_all
          end
          
          it_should_behave_like "all revocations"

          it "should return the number of revoked roles" do
            @sam.revoke!([:developer, :tester], @superapp).should == 2
          end
        end
      end

      context "for finding authorizations for a given resource" do
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

        it "#authorizations.roles_for should return the roles the current person has for the resource" do
          roles = @bob.authorizations.roles_for @maintenance
          roles.should have(2).items
          roles[0].key.should == 'admin'
          roles[1].key.should == 'developer'
        end

        it "#authorizations.for should return the authorizations the current person has for the resource" do
          authz = @bob.authorizations.for @maintenance
          authz.should have(2).items
          authz[0].role.key.should == 'admin'
          authz[0].resource.should == @maintenance
          authz[1].role.key.should == 'developer'
          authz[1].resource.should == @maintenance
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

        it "#authorizations.resources_as should return the roles the current person has for the resource" do
          resources = @bob.authorizations.resources_as [:admin, :team_lead]
          resources.should have(2).items
          resources[0].should == @maintenance
          resources[1].should == @hotness
        end

        it "#authorizations.resources_as should not return duplicates" do
          resources = @bob.authorizations.resources_as [:admin, :developer]
          resources.should have(1).item
        end

        it "#authorizations_as should return the authorizations the current person has for the given roles" do
          authz = @bob.authorizations.as :admin
          authz.should have(1).item
          authz[0].role.key.should == 'admin'
          authz[0].resource.should == @maintenance
        end
      end
    end
  end
end
