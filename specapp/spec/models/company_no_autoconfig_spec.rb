require 'spec_helper'

describe Company, 'interface without activerecord_autoinit' do
  before(:each) do
    @if = Company.interfaces[:search_result]
  end

  it 'has only attributes defined in model definition' do
    @if.attrs.should have_key(:id)
    @if.attrs.should have_key(:search_summary)
    @if.attrs.count.should == 2
  end
end
