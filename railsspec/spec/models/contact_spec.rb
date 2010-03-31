require 'spec_helper'

describe Contact do
  before(:each) do
    @valid_attributes = {
      :owner_id => 1,
      :field => "value for field",
      :value => "value for value"
    }
  end

  it "should create a new instance given valid attributes" do
    Contact.create!(@valid_attributes)
  end
end
