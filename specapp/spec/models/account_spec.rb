require 'spec_helper'

class MockupAAAContext
  attr_reader :global_capabilities
  attr_reader :auth_identity

  def initialize(global_capabilities, auth_identity)
    @global_capabilities = global_capabilities
    @auth_identity = auth_identity
  end
end

context_1 = MockupAAAContext.new([], 1)
context_2 = MockupAAAContext.new([], 2)
context_3 = MockupAAAContext.new([], 3)
context_4 = MockupAAAContext.new([], 4)
context_5 = MockupAAAContext.new([], 5)
context_s = MockupAAAContext.new([ :superuser ], 6)

describe Account do
  describe 'capabilities_for' do
    before(:each) do
      @a1 = FactoryGirl.create(:account1)
      @a2 = FactoryGirl.create(:account2)
      @a3 = FactoryGirl.create(:account3)
    end

    it 'tests inherited capabilities' do
      pending 'to be implemented'
      fail
    end

    it 'tests capability templates' do
      pending 'to be implemented'
      fail
    end

    it 'tests inherited actions' do
      pending 'to be implemented'
      fail
    end

    it 'allow should raise error if allowing an undefined action' do
      pending 'to be implemented'
      fail
    end

    it 'returns model\'s schema with GET /schema' do
      Account.interfaces[:rest].schema.should deep_include({
        :actions => { },
        :capabilities => {
          :creator => {},
          :edit_as_user => {},
          :edit_as_reseller => {},
          :edit_as_admin => {},
          :special_functions => {},
          :superuser => {}
        },
      })
    end

    it 'lists capabilities for Account1' do
      @a1.capabilities_for(context_1).should == [ ]
      @a1.capabilities_for(context_2).should == [ :edit_as_user ]
      @a1.capabilities_for(context_3).should == [ :edit_as_reseller ]
      @a1.capabilities_for(context_4).should == [ :edit_as_admin ]
      @a1.capabilities_for(context_5).should == [ :edit_as_admin, :special_functions ]
      @a1.capabilities_for(context_s).should == [ ]
    end

    it 'lists capabilities for Account2' do
      @a2.capabilities_for(context_1).should == [ ]
      @a2.capabilities_for(context_2).should == [ :edit_as_user ]
      @a2.capabilities_for(context_3).should == [ :edit_as_reseller ]
      @a2.capabilities_for(context_4).should == [ :edit_as_admin ]
      @a2.capabilities_for(context_5).should == [ :edit_as_admin, :special_functions ]
      @a1.capabilities_for(context_s).should == [ ]
    end

    it 'lists capabilities for Account3 (without privileges for any context)' do
      @a3.capabilities_for(context_1).should == [ ]
      @a3.capabilities_for(context_2).should == [ ]
      @a3.capabilities_for(context_3).should == [ ]
      @a3.capabilities_for(context_4).should == [ ]
      @a3.capabilities_for(context_5).should == [ ]
      @a1.capabilities_for(context_s).should == [ ]
    end
  end

  describe 'has_capability?' do
    before(:each) do
      @a1 = FactoryGirl.create(:account1)
      @a2 = FactoryGirl.create(:account2)
      @a3 = FactoryGirl.create(:account3)
    end

    it 'responds correctly with test data' do
      @a1.has_capability?(context_1, :edit_as_user).should be_falsey
      @a1.has_capability?(context_1, :edit_as_reseller).should be_falsey
      @a1.has_capability?(context_1, :edit_as_admin).should be_falsey
      @a1.has_capability?(context_1, :special_functions).should be_falsey
      @a1.has_capability?(context_1, :superuser).should be_falsey

      @a1.has_capability?(context_2, :edit_as_user).should be_truthy
      @a1.has_capability?(context_2, :edit_as_reseller).should be_falsey
      @a1.has_capability?(context_2, :edit_as_admin).should be_falsey
      @a1.has_capability?(context_2, :special_functions).should be_falsey
      @a1.has_capability?(context_2, :superuser).should be_falsey

      @a1.has_capability?(context_3, :edit_as_user).should be_falsey
      @a1.has_capability?(context_3, :edit_as_reseller).should be_truthy
      @a1.has_capability?(context_3, :edit_as_admin).should be_falsey
      @a1.has_capability?(context_3, :special_functions).should be_falsey
      @a1.has_capability?(context_3, :superuser).should be_falsey

      @a1.has_capability?(context_4, :edit_as_user).should be_falsey
      @a1.has_capability?(context_4, :edit_as_reseller).should be_falsey
      @a1.has_capability?(context_4, :edit_as_admin).should be_truthy
      @a1.has_capability?(context_4, :special_functions).should be_falsey
      @a1.has_capability?(context_4, :superuser).should be_falsey

      @a1.has_capability?(context_5, :edit_as_user).should be_falsey
      @a1.has_capability?(context_5, :edit_as_reseller).should be_falsey
      @a1.has_capability?(context_5, :edit_as_admin).should be_truthy
      @a1.has_capability?(context_5, :special_functions).should be_truthy
      @a1.has_capability?(context_5, :superuser).should be_falsey

      @a1.has_capability?(context_s, :edit_as_user).should be_falsey
      @a1.has_capability?(context_s, :edit_as_reseller).should be_falsey
      @a1.has_capability?(context_s, :edit_as_admin).should be_falsey
      @a1.has_capability?(context_s, :special_functions).should be_falsey
      @a1.has_capability?(context_s, :superuser).should be_falsey


      @a2.has_capability?(context_1, :edit_as_user).should be_falsey
      @a2.has_capability?(context_1, :edit_as_reseller).should be_falsey
      @a2.has_capability?(context_1, :edit_as_admin).should be_falsey
      @a2.has_capability?(context_1, :special_functions).should be_falsey
      @a2.has_capability?(context_1, :superuser).should be_falsey

      @a2.has_capability?(context_2, :edit_as_user).should be_truthy
      @a2.has_capability?(context_2, :edit_as_reseller).should be_falsey
      @a2.has_capability?(context_2, :edit_as_admin).should be_falsey
      @a2.has_capability?(context_2, :special_functions).should be_falsey
      @a2.has_capability?(context_2, :superuser).should be_falsey

      @a2.has_capability?(context_3, :edit_as_user).should be_falsey
      @a2.has_capability?(context_3, :edit_as_reseller).should be_truthy
      @a2.has_capability?(context_3, :edit_as_admin).should be_falsey
      @a2.has_capability?(context_3, :special_functions).should be_falsey
      @a2.has_capability?(context_3, :superuser).should be_falsey

      @a2.has_capability?(context_4, :edit_as_user).should be_falsey
      @a2.has_capability?(context_4, :edit_as_reseller).should be_falsey
      @a2.has_capability?(context_4, :edit_as_admin).should be_truthy
      @a2.has_capability?(context_4, :special_functions).should be_falsey
      @a2.has_capability?(context_4, :superuser).should be_falsey

      @a2.has_capability?(context_5, :edit_as_user).should be_falsey
      @a2.has_capability?(context_5, :edit_as_reseller).should be_falsey
      @a2.has_capability?(context_5, :edit_as_admin).should be_truthy
      @a2.has_capability?(context_5, :special_functions).should be_truthy
      @a2.has_capability?(context_5, :superuser).should be_falsey

      @a2.has_capability?(context_s, :edit_as_user).should be_falsey
      @a2.has_capability?(context_s, :edit_as_reseller).should be_falsey
      @a2.has_capability?(context_s, :edit_as_admin).should be_falsey
      @a2.has_capability?(context_s, :special_functions).should be_falsey
      @a2.has_capability?(context_s, :superuser).should be_falsey
      @a2.has_capability?(context_s, :superuser).should be_falsey



      @a3.has_capability?(context_1, :edit_as_user).should be_falsey
      @a3.has_capability?(context_1, :edit_as_reseller).should be_falsey
      @a3.has_capability?(context_1, :edit_as_admin).should be_falsey
      @a3.has_capability?(context_1, :special_functions).should be_falsey
      @a3.has_capability?(context_1, :superuser).should be_falsey

      @a3.has_capability?(context_2, :edit_as_user).should be_falsey
      @a3.has_capability?(context_2, :edit_as_reseller).should be_falsey
      @a3.has_capability?(context_2, :edit_as_admin).should be_falsey
      @a3.has_capability?(context_2, :special_functions).should be_falsey
      @a3.has_capability?(context_2, :superuser).should be_falsey

      @a3.has_capability?(context_3, :edit_as_user).should be_falsey
      @a3.has_capability?(context_3, :edit_as_reseller).should be_falsey
      @a3.has_capability?(context_3, :edit_as_admin).should be_falsey
      @a3.has_capability?(context_3, :special_functions).should be_falsey
      @a3.has_capability?(context_3, :superuser).should be_falsey

      @a3.has_capability?(context_4, :edit_as_user).should be_falsey
      @a3.has_capability?(context_4, :edit_as_reseller).should be_falsey
      @a3.has_capability?(context_4, :edit_as_admin).should be_falsey
      @a3.has_capability?(context_4, :special_functions).should be_falsey
      @a3.has_capability?(context_4, :superuser).should be_falsey

      @a3.has_capability?(context_5, :edit_as_user).should be_falsey
      @a3.has_capability?(context_5, :edit_as_reseller).should be_falsey
      @a3.has_capability?(context_5, :edit_as_admin).should be_falsey
      @a3.has_capability?(context_5, :special_functions).should be_falsey
      @a3.has_capability?(context_5, :superuser).should be_falsey

      @a3.has_capability?(context_s, :edit_as_user).should be_falsey
      @a3.has_capability?(context_s, :edit_as_reseller).should be_falsey
      @a3.has_capability?(context_s, :edit_as_admin).should be_falsey
      @a3.has_capability?(context_s, :special_functions).should be_falsey
      @a3.has_capability?(context_s, :superuser).should be_falsey
    end
  end

  describe 'attr_readable?' do
    it 'responds false to user without privileges' do
      Account.interfaces[:rest].attr_readable?([], :name).should be_falsey
      Account.interfaces[:rest].attr_readable?([], :balance).should be_falsey
      Account.interfaces[:rest].attr_readable?([], :secret).should be_falsey
    end

    it 'allows reading of unprivileged atttribute "name" to authorized identities with user role' do
      Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :name).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :balance).should be_falsey
      Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :secret).should be_falsey
    end

    it 'allows reading of some attributes to authorized identities with reseller role' do
      Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :name).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :balance).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :secret).should be_falsey
    end

    it 'allows reading of all attributes to authorized identities with admin role (using defaults)' do
      Account.interfaces[:rest].attr_readable?([ :edit_as_admin ], :name).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :edit_as_admin ], :balance).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :edit_as_admin ], :secret).should be_truthy
    end

    it 'does not allow reading to identities with special_functions (which only allows an action)' do
      Account.interfaces[:rest].attr_readable?([ :special_functions ], :name).should be_falsey
      Account.interfaces[:rest].attr_readable?([ :special_functions ], :balance).should be_falsey
      Account.interfaces[:rest].attr_readable?([ :special_functions ], :secret).should be_falsey
    end

    it 'allow reading to identities with superuser' do
      Account.interfaces[:rest].attr_readable?([ :superuser ], :name).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :superuser ], :balance).should be_truthy
      Account.interfaces[:rest].attr_readable?([ :superuser ], :secret).should be_truthy
    end
  end

  describe 'attr_writable?' do
    it 'responds false to user without privileges' do
      Account.interfaces[:rest].attr_writable?([], :name).should be_falsey
      Account.interfaces[:rest].attr_writable?([], :balance).should be_falsey
      Account.interfaces[:rest].attr_writable?([], :secret).should be_falsey
    end

    it 'disallows writing of to identities with "user" role' do
      Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :name).should be_falsey
      Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :balance).should be_falsey
      Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :secret).should be_falsey
    end

    it 'allows writing of name to identities with "reseller" role' do
      Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :name).should be_truthy
      Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :balance).should be_falsey
      Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :secret).should be_falsey
    end

    it 'allows writing of all attributes to identities with "admin" role (using defaults)' do
      Account.interfaces[:rest].attr_writable?([ :edit_as_admin ], :name).should be_truthy
      Account.interfaces[:rest].attr_writable?([ :edit_as_admin ], :balance).should be_truthy
      Account.interfaces[:rest].attr_writable?([ :edit_as_admin ], :secret).should be_truthy
    end

    it 'does not allow writing to identities with special_functions (which only allows an action)' do
      Account.interfaces[:rest].attr_writable?([ :special_functions ], :name).should be_falsey
      Account.interfaces[:rest].attr_writable?([ :special_functions ], :balance).should be_falsey
      Account.interfaces[:rest].attr_writable?([ :special_functions ], :secret).should be_falsey
    end

    it 'allows writing to identities with superuser' do
      Account.interfaces[:rest].attr_writable?([ :superuser ], :name).should be_truthy
      Account.interfaces[:rest].attr_writable?([ :superuser ], :balance).should be_truthy
      Account.interfaces[:rest].attr_writable?([ :superuser ], :secret).should be_truthy
    end
  end

  describe 'ar_serializable_hash' do
    before(:each) do
      @a1 = FactoryGirl.create(:account1)
      @a2 = FactoryGirl.create(:account2)
      @a3 = FactoryGirl.create(:account3)
    end

    it 'raises ResourceNotReadable for Account1 in context_1' do
      lambda { @a1.ar_serializable_hash(:rest, :aaa_context => context_1) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotReadable)
    end

    it 'returns only edit_as_user attributes for Account1 in context_2' do
      @a1.ar_serializable_hash(:rest, :aaa_context => context_2).should ==
        { :_type => 'Account', :name => 'Account1' }
    end

    it 'returns edit_as_reseller attributes for Account1 in context_3' do
      @a1.ar_serializable_hash(:rest, :aaa_context => context_3).should ==
        { :_type => 'Account', :name => 'Account1', :balance => 10 }
    end

    it 'returns edit_as_admin attributes for Account1 in context_4' do
      @a1.ar_serializable_hash(:rest, :aaa_context => context_4).should ==
        { :_type => 'Account', :id => 1, :name => 'Account1', :balance => 10, :secret => "Pippo" }
    end

    it 'returns admin_as_admin attributes for Account1 in context_5' do
      @a1.ar_serializable_hash(:rest, :aaa_context => context_5).should ==
        { :_type => 'Account', :id => 1, :name => 'Account1', :balance => 10, :secret => "Pippo" }
    end

    it 'returns all attributes for Account1 in context_s' do
      @a1.ar_serializable_hash(:rest, :aaa_context => context_s).should ==
        { :_type => 'Account', :id => 1, :name => 'Account1', :balance => 10, :secret => "Pippo" }
    end


    it 'raises ResourceNotReadable for Account2 in context_1' do
      lambda { @a2.ar_serializable_hash(:rest, :aaa_context => context_1) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotReadable)
    end

    it 'returns only edit_as_user attributes for Account2 in context_2' do
      @a2.ar_serializable_hash(:rest, :aaa_context => context_2).should ==
        { :_type => 'Account', :name => 'Account2' }
    end

    it 'returns edit_as_reseller attributes for Account2 in context_3' do
      @a2.ar_serializable_hash(:rest, :aaa_context => context_3).should ==
        { :_type => 'Account', :name => 'Account2', :balance => 20 }
    end

    it 'returns edit_as_admin attributes for Account2 in context_4' do
      @a2.ar_serializable_hash(:rest, :aaa_context => context_4).should ==
        { :_type => 'Account', :id => 2, :name => 'Account2', :balance => 20, :secret => "Pluto" }
    end

    it 'returns admin_as_admin attributes for Account2 in context_5' do
      @a2.ar_serializable_hash(:rest, :aaa_context => context_5).should ==
        { :_type => 'Account', :id => 2, :name => 'Account2', :balance => 20, :secret => "Pluto" }
    end

    it 'returns all attributes for Account2 in context_s' do
      @a2.ar_serializable_hash(:rest, :aaa_context => context_s).should ==
        { :_type => 'Account', :id => 2, :name => 'Account2', :balance => 20, :secret => "Pluto" }
    end


    it 'raises ResourceNotReadable for Account3 in context_1' do
      lambda { @a3.ar_serializable_hash(:rest, :aaa_context => context_1) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotReadable)
    end

    it 'raises ResourceNotReadable for Account3 in context_2' do
      lambda { @a3.ar_serializable_hash(:rest, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotReadable)
    end

    it 'raises ResourceNotReadable for Account3 in context_3' do
      lambda { @a3.ar_serializable_hash(:rest, :aaa_context => context_3) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotReadable)
    end

    it 'returns no attributes for Account3 in context_4' do
      @a3.ar_serializable_hash(:rest, :aaa_context => context_4).should ==
        { :_type => 'Account' }
    end

    it 'raises ResourceNotReadable for Account3 in context_5' do
      lambda { @a3.ar_serializable_hash(:rest, :aaa_context => context_5) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotReadable)
    end

    it 'returns all attributes for Account3 in context_s' do
      @a3.ar_serializable_hash(:rest, :aaa_context => context_s).should ==
        { :_type => 'Account', :id => 3, :name => 'Account3 Sfigato', :balance => -30, :secret => "Paperino" }
    end

  end

  describe 'apply_update_attributes' do
    before(:each) do
      @a1 = FactoryGirl.create(:account1)
      @a2 = FactoryGirl.create(:account2)
      @a3 = FactoryGirl.create(:account3)
    end

    it 'does not raise an error when empty update is specified' do
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_2) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_3) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_4) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_5) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_s) }.should_not raise_error

      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_2) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_3) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_4) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_5) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_s) }.should_not raise_error

      lambda { @a3.ar_apply_update_attributes(:rest, { }, :aaa_context => context_s) }.should_not raise_error
    end

    it 'raise an error when not writable attributes are specified' do
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo' }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)

      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)

      lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)

      lambda { @a1.ar_apply_update_attributes(:rest, { :balance => 15 }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)


      lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_3) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)

      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_3) }.
       should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)
    end
  end

  describe 'ar_apply_update_attributes' do
    before(:each) do
      @a1 = FactoryGirl.create(:account1)
      @a2 = FactoryGirl.create(:account2)
      @a3 = FactoryGirl.create(:account3)
    end

    it 'does not raise an error when empty update is specified if the resource is accessible in some way' do
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_2) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_3) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_4) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_5) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { }, :aaa_context => context_s) }.should_not raise_error

      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_2) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_3) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_4) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_5) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { }, :aaa_context => context_s) }.should_not raise_error

      lambda { @a3.ar_apply_update_attributes(:rest, { }, :aaa_context => context_s) }.should_not raise_error
    end

    it 'does not raise an error when writable attributes are written' do
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'newname' }, :aaa_context => context_3) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_4) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_5) }.should_not raise_error
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_s) }.should_not raise_error

      lambda { @a2.ar_apply_update_attributes(:rest, { :name => 'newname' }, :aaa_context => context_3) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_4) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_5) }.should_not raise_error
      lambda { @a2.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_s) }.should_not raise_error

      lambda { @a3.ar_apply_update_attributes(:rest, { :name => 'newname', :balance => 0, :secret => 'new_secret' },
                                              :aaa_context => context_s) }.should_not raise_error
    end

    it 'raises a ResourceNotWritable error when the whole resource is not writable' do
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo' }, :aaa_context => context_1) }.
        should raise_error(ActiveRest::Model::Interface::ResourceNotWritable)
    end

    it 'raises a AttributeNotWritable when not writable attributes are specified' do
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo' }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)
      lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)
      lambda { @a1.ar_apply_update_attributes(:rest, { :balance => 15 }, :aaa_context => context_2) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)

      lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_3) }.
        should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)
      lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_3) }.
       should raise_error(ActiveRest::Model::Interface::AttributeNotWritable)
    end
  end

  describe 'interface[:rest].allow_action?' do
    before(:each) do
      @a1 = FactoryGirl.create(:account1)
      @a2 = FactoryGirl.create(:account2)
      @a3 = FactoryGirl.create(:account3)
    end

    it 'allows special_action to users with special_functions capabilities' do
      @a1.interfaces[:rest].action_allowed?([ :special_functions ], :special_action).should be_truthy
    end

    it 'allows special_action to users with superuser capabilities' do
      @a1.interfaces[:rest].action_allowed?([ :superuser ], :special_action).should be_truthy
    end

    it 'denies special_action to users with no capabilities' do
      @a1.interfaces[:rest].action_allowed?([ ], :special_action).should be_falsey
    end

    it 'denies special_action to users with any other capabilities' do
      @a1.interfaces[:rest].action_allowed?([ :edit_as_user, :edit_as_admin, :edit_as_reseller ], :special_action).should be_falsey
    end
  end
end
