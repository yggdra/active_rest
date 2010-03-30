#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.dirname(__FILE__) + '/../spec_helper'

class Company < ActiveRecord::Base
  set_table_name 'active_rest_companies'
  attr_order :name, :street, :zip, :city

  attr_groups :city => [:street ],
              :area => %w(zip city),
              :all => [:name, :city, :area]

end


describe Company, '.ordered_attributes with group in group' do

   before(:each) do
     @company = Company.new
     @company.attributes.keys.should == ['name', 'city', 'zip', 'street'] # not sure if this order is always applied by default, but added this test to make sure the plugin actually has an effect
   end

   it 'should return ordered attributes' do
     Company.ordered_attributes.should == [:name, :street, :zip, :street]
   end

   it 'should return group attributes' do
     Company.ordered_attributes([:area]).should == [:zip, :street]
   end

   it 'should return group attributes and convert the attribute names to symbols' do
     Company.ordered_attributes(:area).should == [:zip, :street]
   end

   it 'should return group in group attributes, when passed as array' do
     Company.ordered_attributes([:all]).should == [:name, :street, :zip, :street]
   end

   it 'should return group in group attributes, when passed as argument' do
     Company.ordered_attributes(:all).should == [:name, :street, :zip, :street]
   end

end
