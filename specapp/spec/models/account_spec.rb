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

describe Account, 'capabilities_for' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
    @a2= FactoryGirl.create(:account2)
    @a3= FactoryGirl.create(:account3)
  end

  it 'responds correctly with test data' do
    @a1.capabilities_for(context_1).should == [ ]
    @a1.capabilities_for(context_2).should == [ :edit_as_user ]
    @a1.capabilities_for(context_3).should == [ :edit_as_reseller ]
    @a2.capabilities_for(context_1).should == [ ]
    @a2.capabilities_for(context_2).should == [ :edit_as_user ]
    @a2.capabilities_for(context_3).should == [ :edit_as_reseller ]
    @a3.capabilities_for(context_1).should == [ ]
    @a3.capabilities_for(context_2).should == [ :edit_as_user ]
    @a3.capabilities_for(context_3).should == [ :edit_as_reseller ]
  end
end

describe Account, 'can?' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
    @a2= FactoryGirl.create(:account2)
    @a3= FactoryGirl.create(:account3)
  end

  it 'responds correctly with test data' do
    @a1.can?(context_1, :edit_as_user).should == false
    @a1.can?(context_1, :edit_as_reseller).should == false
    @a1.can?(context_2, :edit_as_user).should == true
    @a1.can?(context_2, :edit_as_reseller).should == false
    @a1.can?(context_3, :edit_as_user).should == false
    @a1.can?(context_3, :edit_as_reseller).should == true
    @a2.can?(context_1, :edit_as_user).should == false
    @a2.can?(context_1, :edit_as_reseller).should == false
    @a2.can?(context_2, :edit_as_user).should == true
    @a2.can?(context_2, :edit_as_reseller).should == false
    @a2.can?(context_3, :edit_as_user).should == false
    @a2.can?(context_3, :edit_as_reseller).should == true
    @a3.can?(context_1, :edit_as_user).should == false
    @a3.can?(context_1, :edit_as_reseller).should == false
    @a3.can?(context_2, :edit_as_user).should == true
    @a3.can?(context_2, :edit_as_reseller).should == false
    @a3.can?(context_3, :edit_as_user).should == false
    @a3.can?(context_3, :edit_as_reseller).should == true
  end
end

describe Account, 'interface attributes are readable' do
  it 'responds correctly with test data' do
    Account.interfaces[:rest].attr_readable?([], :name).should == false
    Account.interfaces[:rest].attr_readable?([], :secret).should == false
    Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :name).should == true
    Account.interfaces[:rest].attr_readable?([ :edit_as_user ], :secret).should == false
    Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :name).should == true
    Account.interfaces[:rest].attr_readable?([ :edit_as_reseller ], :secret).should == true
  end
end

describe Account, 'interface attributes are writable' do
  it 'responds correctly with test data' do
    Account.interfaces[:rest].attr_writable?([], :name).should == false
    Account.interfaces[:rest].attr_writable?([], :secret).should == false
    Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :name).should == false
    Account.interfaces[:rest].attr_writable?([ :edit_as_user ], :secret).should == false
    Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :name).should == true
    Account.interfaces[:rest].attr_writable?([ :edit_as_reseller ], :secret).should == false
  end
end

describe Account, 'ar_serializable_hash' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
  end

  it 'returns only authorized attributes' do
    @a1.ar_serializable_hash(:rest, :aaa_context => context_1).should ==
      { :_type => 'Account' }
    @a1.ar_serializable_hash(:rest, :aaa_context => context_2).should ==
      { :_type => 'Account', :name => 'Account1' }
    @a1.ar_serializable_hash(:rest, :aaa_context => context_3).should ==
      { :_type => 'Account', :name => 'Account1', :secret => "Pippo" }
  end
end

describe Account, 'apply_update_attributes' do
  before(:each) do
    @a1= FactoryGirl.create(:account1)
  end

  it 'raise an error when not writeable attributes are specified' do
    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { },
        :aaa_context => context_1)
    }.should_not raise_error

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :name => 'Foo' },
        :aaa_context => context_1)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :name => 'Foo', :secret => 'Bar' },
        :aaa_context => context_1)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :secret => 'Bar' },
        :aaa_context => context_1)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)


    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { },
        :aaa_context => context_2)
    }.should_not raise_error

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :name => 'Foo' },
        :aaa_context => context_2)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :name => 'Foo', :secret => 'Bar' },
        :aaa_context => context_2)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :secret => 'Bar' },
        :aaa_context => context_2)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)


    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { },
        :aaa_context => context_3)
    }.should_not raise_error

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :name => 'Foo' },
        :aaa_context => context_3)
    }.should_not raise_error

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :name => 'Foo', :secret => 'Bar' },
        :aaa_context => context_3)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

    lambda {
      @a1.ar_apply_update_attributes(:rest,
        { :secret => 'Bar' },
        :aaa_context => context_3)
    }.should raise_error(ActiveRest::Model::Interface::AttributeNotWriteable)

  end
end


