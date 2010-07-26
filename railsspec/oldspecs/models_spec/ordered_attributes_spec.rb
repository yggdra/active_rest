#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.dirname(__FILE__) + '/../spec_helper'

class Company < ActiveRecord::Base
  set_table_name 'active_rest_companies'

  attr_order %w(name street zip city)
end

describe Company, 'with an array passed to attr_order' do
  it 'should return default ordered attributes, when no arguments are passed' do
    Company.ordered_attributes.should == [:name, :street, :zip, :city]
  end
end

