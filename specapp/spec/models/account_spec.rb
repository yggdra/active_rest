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

describe Account, 'capabilities_for' do
  before(:each) do
    @a1 = FactoryGirl.create(:account1)
    @a2 = FactoryGirl.create(:account2)
    @a3 = FactoryGirl.create(:account3)
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

describe Account, 'can?' do
  before(:each) do
    @a1 = FactoryGirl.create(:account1)
    @a2 = FactoryGirl.create(:account2)
    @a3 = FactoryGirl.create(:account3)
  end

  it 'responds correctly with test data' do
    @a1.can?(context_1, :edit_as_user).should be_false
    @a1.can?(context_1, :edit_as_reseller).should be_false
    @a1.can?(context_1, :edit_as_admin).should be_false
    @a1.can?(context_1, :special_functions).should be_false
    @a1.can?(context_1, :superuser).should be_false

    @a1.can?(context_2, :edit_as_user).should be_true
    @a1.can?(context_2, :edit_as_reseller).should be_false
    @a1.can?(context_2, :edit_as_admin).should be_false
    @a1.can?(context_2, :special_functions).should be_false
    @a1.can?(context_2, :superuser).should be_false

    @a1.can?(context_3, :edit_as_user).should be_false
    @a1.can?(context_3, :edit_as_reseller).should be_true
    @a1.can?(context_3, :edit_as_admin).should be_false
    @a1.can?(context_3, :special_functions).should be_false
    @a1.can?(context_3, :superuser).should be_false

    @a1.can?(context_4, :edit_as_user).should be_false
    @a1.can?(context_4, :edit_as_reseller).should be_false
    @a1.can?(context_4, :edit_as_admin).should be_true
    @a1.can?(context_4, :special_functions).should be_false
    @a1.can?(context_4, :superuser).should be_false

    @a1.can?(context_5, :edit_as_user).should be_false
    @a1.can?(context_5, :edit_as_reseller).should be_false
    @a1.can?(context_5, :edit_as_admin).should be_true
    @a1.can?(context_5, :special_functions).should be_true
    @a1.can?(context_5, :superuser).should be_false

    @a1.can?(context_s, :edit_as_user).should be_false
    @a1.can?(context_s, :edit_as_reseller).should be_false
    @a1.can?(context_s, :edit_as_admin).should be_false
    @a1.can?(context_s, :special_functions).should be_false
    @a1.can?(context_s, :superuser).should be_false


    @a2.can?(context_1, :edit_as_user).should be_false
    @a2.can?(context_1, :edit_as_reseller).should be_false
    @a2.can?(context_1, :edit_as_admin).should be_false
    @a2.can?(context_1, :special_functions).should be_false
    @a2.can?(context_1, :superuser).should be_false

    @a2.can?(context_2, :edit_as_user).should be_true
    @a2.can?(context_2, :edit_as_reseller).should be_false
    @a2.can?(context_2, :edit_as_admin).should be_false
    @a2.can?(context_2, :special_functions).should be_false
    @a2.can?(context_2, :superuser).should be_false

    @a2.can?(context_3, :edit_as_user).should be_false
    @a2.can?(context_3, :edit_as_reseller).should be_true
    @a2.can?(context_3, :edit_as_admin).should be_false
    @a2.can?(context_3, :special_functions).should be_false
    @a2.can?(context_3, :superuser).should be_false

    @a2.can?(context_4, :edit_as_user).should be_false
    @a2.can?(context_4, :edit_as_reseller).should be_false
    @a2.can?(context_4, :edit_as_admin).should be_true
    @a2.can?(context_4, :special_functions).should be_false
    @a2.can?(context_4, :superuser).should be_false

    @a2.can?(context_5, :edit_as_user).should be_false
    @a2.can?(context_5, :edit_as_reseller).should be_false
    @a2.can?(context_5, :edit_as_admin).should be_true
    @a2.can?(context_5, :special_functions).should be_true
    @a2.can?(context_5, :superuser).should be_false

    @a2.can?(context_s, :edit_as_user).should be_false
    @a2.can?(context_s, :edit_as_reseller).should be_false
    @a2.can?(context_s, :edit_as_admin).should be_false
    @a2.can?(context_s, :special_functions).should be_false
    @a2.can?(context_s, :superuser).should be_false
    @a2.can?(context_s, :superuser).should be_false



    @a3.can?(context_1, :edit_as_user).should be_false
    @a3.can?(context_1, :edit_as_reseller).should be_false
    @a3.can?(context_1, :edit_as_admin).should be_false
    @a3.can?(context_1, :special_functions).should be_false
    @a3.can?(context_1, :superuser).should be_false

    @a3.can?(context_2, :edit_as_user).should be_false
    @a3.can?(context_2, :edit_as_reseller).should be_false
    @a3.can?(context_2, :edit_as_admin).should be_false
    @a3.can?(context_2, :special_functions).should be_false
    @a3.can?(context_2, :superuser).should be_false

    @a3.can?(context_3, :edit_as_user).should be_false
    @a3.can?(context_3, :edit_as_reseller).should be_false
    @a3.can?(context_3, :edit_as_admin).should be_false
    @a3.can?(context_3, :special_functions).should be_false
    @a3.can?(context_3, :superuser).should be_false

    @a3.can?(context_4, :edit_as_user).should be_false
    @a3.can?(context_4, :edit_as_reseller).should be_false
    @a3.can?(context_4, :edit_as_admin).should be_false
    @a3.can?(context_4, :special_functions).should be_false
    @a3.can?(context_4, :superuser).should be_false

    @a3.can?(context_5, :edit_as_user).should be_false
    @a3.can?(context_5, :edit_as_reseller).should be_false
    @a3.can?(context_5, :edit_as_admin).should be_false
    @a3.can?(context_5, :special_functions).should be_false
    @a3.can?(context_5, :superuser).should be_false

    @a3.can?(context_s, :edit_as_user).should be_false
    @a3.can?(context_s, :edit_as_reseller).should be_false
    @a3.can?(context_s, :edit_as_admin).should be_false
    @a3.can?(context_s, :special_functions).should be_false
    @a3.can?(context_s, :superuser).should be_false
  end
end

describe Account, 'attr_readable?' do
  it 'responds false to user without privileges' do
    Account.interfaces[:rest].attr_readable?([], :name).should be_false
    Account.interfaces[:rest].attr_readable?([], :balance).should be_false
    Account.interfaces[:rest].attr_readable?([], :secret).should be_false
  end

  it 'allows reading of unprivileged atttribute "name" to authorized identities with user role' do
    Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :name).should be_true
    Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :balance).should be_false
    Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :secret).should be_false
  end

  it 'allows reading of some attributes to authorized identities with reseller role' do
    Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :name).should be_true
    Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :balance).should be_true
    Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :secret).should be_false
  end

  it 'allows reading of all attributes to authorized identities with admin role (using defaults)' do
    Account.interfaces[:rest].attr_readable?([ :edit_as_admin ], :name).should be_true
    Account.interfaces[:rest].attr_readable?([ :edit_as_admin ], :balance).should be_true
    Account.interfaces[:rest].attr_readable?([ :edit_as_admin ], :secret).should be_true
  end

  it 'does not allow reading to identities with special_functions (which only allows an action)' do
    Account.interfaces[:rest].attr_readable?([ :special_functions ], :name).should be_false
    Account.interfaces[:rest].attr_readable?([ :special_functions ], :balance).should be_false
    Account.interfaces[:rest].attr_readable?([ :special_functions ], :secret).should be_false
  end

  it 'allow reading to identities with superuser' do
    Account.interfaces[:rest].attr_readable?([ :superuser ], :name).should be_true
    Account.interfaces[:rest].attr_readable?([ :superuser ], :balance).should be_true
    Account.interfaces[:rest].attr_readable?([ :superuser ], :secret).should be_true
  end
end

describe Account, 'attr_writable?' do
  it 'responds false to user without privileges' do
    Account.interfaces[:rest].attr_writable?([], :name).should be_false
    Account.interfaces[:rest].attr_writable?([], :balance).should be_false
    Account.interfaces[:rest].attr_writable?([], :secret).should be_false
  end

  it 'disallows writing of to identities with "user" role' do
    Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :name).should be_false
    Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :balance).should be_false
    Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :secret).should be_false
  end

  it 'allows writing of name to identities with "reseller" role' do
    Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :name).should be_true
    Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :balance).should be_false
    Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :secret).should be_false
  end

  it 'allows writing of all attributes to identities with "admin" role (using defaults)' do
    Account.interfaces[:rest].attr_writable?([ :edit_as_admin ], :name).should be_true
    Account.interfaces[:rest].attr_writable?([ :edit_as_admin ], :balance).should be_true
    Account.interfaces[:rest].attr_writable?([ :edit_as_admin ], :secret).should be_true
  end

  it 'does not allow writing to identities with special_functions (which only allows an action)' do
    Account.interfaces[:rest].attr_writable?([ :special_functions ], :name).should be_false
    Account.interfaces[:rest].attr_writable?([ :special_functions ], :balance).should be_false
    Account.interfaces[:rest].attr_writable?([ :special_functions ], :secret).should be_false
  end

  it 'allows writing to identities with superuser' do
    Account.interfaces[:rest].attr_writable?([ :superuser ], :name).should be_true
    Account.interfaces[:rest].attr_writable?([ :superuser ], :balance).should be_true
    Account.interfaces[:rest].attr_writable?([ :superuser ], :secret).should be_true
  end
end

describe Account, 'ar_serializable_hash' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
    @a2= FactoryGirl.create(:account2)
    @a3= FactoryGirl.create(:account3)
  end

  it 'returns no attributes for Account1 in context_1' do
    @a1.ar_serializable_hash(:rest, :aaa_context => context_1).should ==
      { :_type => 'Account' }
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


  it 'returns no attributes for Account2 in context_1' do
    @a2.ar_serializable_hash(:rest, :aaa_context => context_1).should ==
      { :_type => 'Account' }
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


  it 'returns no attributes for Account3 in context_1' do
    @a3.ar_serializable_hash(:rest, :aaa_context => context_1).should ==
      { :_type => 'Account' }
  end

  it 'returns no attributes for Account3 in context_2' do
    @a3.ar_serializable_hash(:rest, :aaa_context => context_2).should ==
      { :_type => 'Account' }
  end

  it 'returns no attributes for Account3 in context_3' do
    @a3.ar_serializable_hash(:rest, :aaa_context => context_3).should ==
      { :_type => 'Account' }
  end

  it 'returns no attributes for Account3 in context_4' do
    @a3.ar_serializable_hash(:rest, :aaa_context => context_4).should ==
      { :_type => 'Account' }
  end

  it 'returns no attributes for Account3 in context_5' do
    @a3.ar_serializable_hash(:rest, :aaa_context => context_5).should ==
      { :_type => 'Account' }
  end

  it 'returns all attributes for Account3 in context_s' do
    @a3.ar_serializable_hash(:rest, :aaa_context => context_s).should ==
      { :_type => 'Account', :id => 3, :name => 'Account3 Sfigato', :balance => -30, :secret => "Paperino" }
  end

end

describe Account, 'apply_update_attributes' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
    @a2= FactoryGirl.create(:account2)
    @a3= FactoryGirl.create(:account3)
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

  it 'raise an error when not writeable attributes are specified' do
    lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo' }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :balance => 15 }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)


    lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_3) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_3) }.
     should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)
  end
end

describe Account, '' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
    @a2= FactoryGirl.create(:account2)
    @a3= FactoryGirl.create(:account3)
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

  it 'raise an error when not writeable attributes are specified' do
    lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo' }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :balance => 15 }, :aaa_context => context_2) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)


    lambda { @a1.ar_apply_update_attributes(:rest, { :secret => 'Bar' }, :aaa_context => context_3) }.
      should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda { @a1.ar_apply_update_attributes(:rest, { :name => 'Foo', :secret => 'Bar' }, :aaa_context => context_3) }.
     should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)
  end
end
