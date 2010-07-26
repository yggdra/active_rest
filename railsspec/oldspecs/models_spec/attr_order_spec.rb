#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.dirname(__FILE__) + '/../spec_helper'

class Company < ActiveRecord::Base
  set_table_name 'active_rest_companies'

  attr_order :name, :street, :zip, :city
end

#
# COMPANY att_order
#
describe Company, 'with attr_order' do
   it 'should have a ordered_attributes class method' do
     Company.respond_to?(:ordered_attributes).should == true
   end
end


#
# 1^
#
describe Company, '.ordered_attributes' do

   before(:each) do
     @company = Company.new
     @company.attributes.keys.should == ['name', 'city', 'zip', 'street'] # not sure if this order is always applied by default, but added this test to make sure the plugin actually has an effect
   end

   it 'should return default ordered attributes, when no arguments are passed' do
     Company.ordered_attributes.should == [:name, :street, :zip, :city]
   end

   it 'should return default ordered attributes, when empty array is passed' do
     Company.ordered_attributes([]).should == [:name, :street, :zip, :city]
   end

   it 'should return default ordered attributes, when array with empty array is passed' do
     Company.ordered_attributes([[]]).should == [:name, :street, :zip, :city]
   end

   it 'should return custom attributes, when passed as array of symbols' do
     Company.ordered_attributes([:street, :zip, :city]).should == [:street, :zip, :city]
   end

   it 'should return custom attributes, when passed as array of strings' do
     Company.ordered_attributes(%w(street zip city)).should == [:street, :zip, :city]
   end

   it 'should return custom attributes, when passed as arguments' do
     Company.ordered_attributes(:street, :zip, :city).should == [:street, :zip, :city]
   end

end

#
# 2^
#
describe Company, 'any method with wildcard arguments that is calling .ordered_attributes' do

  def wildcard(*attributes)
    Company.ordered_attributes(attributes)
  end

  it 'should return default ordered attributes, when no arguments are passed' do
    wildcard.should == [:name, :street, :zip, :city]
  end

  it 'should return custom attributes, when arguments are passed' do
    wildcard(:zip, :city).should == [:zip, :city]
  end

end
