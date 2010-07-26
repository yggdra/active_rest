#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__)+ '/../models/company')
require File.expand_path(File.dirname(__FILE__)+ '/../models/user')
require File.expand_path(File.dirname(__FILE__)+ '/../models/contact')

class CompanyFindersController < ActionController::Base
  layout false
  rest_controller_for Company
end

#
# REST - INDEX with BASE finder
#
# - sort: name of field to base ordering
# - dir: ordering direction (asc, desc)
# - limit: any positive number will limit the page results
# - offset: any positive number will delimit left-side limit
# - fields: a string or an array ([fld1,fld2...]) of fields to search in
# - like: a string or an array  ([fld1,fld2...]) of criteria to macth with like %% operator
# - query: a string or an array ([fld1,fld2...]) of criteria with exact matching
# - jc: a string rappresenting the join condition (AND is default)
#
describe CompanyFindersController do

  set_fixture_class :companies => Company
  fixtures :companies


  before(:each) do
  end

  it 'should be able to call index with OR' do
    get :index, :format => 'xml', :fields => '[name,city]', :like => '[tm,spring]', :jc => 'OR', :basic => true

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should be able to call index with AND' do
    get :index, :format => 'xml', :fields => '[name,city]', :like => '[new,spring]', :basic => true

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
  end
end
