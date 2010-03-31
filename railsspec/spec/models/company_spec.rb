require 'spec_helper'

describe Company do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :city => "value for city",
      :street => "value for street",
      :zip => "value for zip"
    }
  end

  it "should create a new instance given valid attributes" do
    Company.create!(@valid_attributes)
  end
end
