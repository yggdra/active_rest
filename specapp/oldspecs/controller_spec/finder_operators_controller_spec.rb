#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__)+ '/../models/company')
require File.expand_path(File.dirname(__FILE__)+ '/../models/user')

#=begin
#
# FINDER without joins
#
class FinderOperatorsController < ActionController::Base
  layout false
  ar_controller_for Company, :index_options => { :finder => :operators }
end

describe FinderOperatorsController do

  set_fixture_class :companies => Company
  fixtures :companies

  before(:each) do
  end

  it 'should be allow index action' do
    get :index, :format => 'xml', :filter => '[[id,gt,1]]'

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should be not run an invalid operator filter and return a simple select' do
    get :index, :format => 'xml', :filter => '[[id,unknown_operator,1]]'

    response.should be_success
    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should be not run an invalid field filter and return a simple select' do
    get :index, :format => 'xml', :filter => '[[id_invalid_fld,gt,1]]'

    response.should be_success
    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should map arguments to target_model correctly (1)' do
    get :index, :format => 'xml', :filter => "[['company[id]',gt,1]]"

    response.should be_success
    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should map arguments to target_model correctly (2)' do
    get :index, :format => 'xml', :filter => "[['Company[id]',gt,5]]"

    response.should be_success
    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
  end


  it 'should map arguments to target_model correctly (3)' do
    get :index, :format => 'xml', :filter => "[['Company[name]',begins,'new']]"

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
  end
end



#
# FINDER with joins - no remapping
#
class FinderOperatorsWJController < ActionController::Base
  layout false
  ar_controller_for Company, :index_options => { :finder => :Operators },
                               :model_options => { :join => { :users => true } }
end
describe FinderOperatorsWJController do

  set_fixture_class :companies => Company
  fixtures :companies
  set_fixture_class :users => User
  fixtures :users

  before(:each) do
  end

  it 'should map arguments to joins tables correctly' do
    get :index, :format => 'xml', :filter => "[['users[id]',gt,3]]"

    #puts response.body
    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
    response.should include_text('<users-name type="">' + users(:maggie_simpson).name + '</users-name>')
  end

  it 'should fallback to target_model field correctly (1)' do
    get :index, :format => 'xml', :filter => "[[id,gt,2]]"

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<users-name type="">' + users(:marge_simpson).name + '</users-name>')
    response.should include_text('<users-name type="">' + users(:bart_simpson).name + '</users-name>')
  end


  it 'should fallback to target_model field correctly (2)' do
    get :index, :format => 'xml', :filter => "[['company[id]',gt,2]]"

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<users-name type="">' + users(:marge_simpson).name + '</users-name>')
    response.should include_text('<users-name type="">' + users(:bart_simpson).name + '</users-name>')
  end

  it 'should fallback to target_model field correctly (2)' do
    get :index, :format => 'xml', :filter => "[['users_id',gt,2]]"

    #puts response.body
    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')

    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<users-name type="">' + users(:marge_simpson).name + '</users-name>')
    response.should include_text('<users-name type="">' + users(:maggie_simpson).name + '</users-name>')
  end
end

#
# FINDER with joins - yes remapping
#
class FinderOperatorsWJoinAndMappingController < ActionController::Base
  layout false
  ar_controller_for Company, :index_options => {:finder => :Operators},
  :model_options => { :join => { :users => { :name => 'my_name'} } }
end
describe FinderOperatorsWJoinAndMappingController do

  set_fixture_class :companies => Company
  fixtures :companies
  set_fixture_class :users => User
  fixtures :users

  before(:each) do
  end

  it 'should map arguments to joins tables correctly' do
    get :index, :format => 'xml', :filter => "[[my_name,begins,'bart']]"

    #puts response.body
    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<my-name type="">' + users(:bart_simpson).name + '</my-name>')
  end

  it 'should not map arguments to joins tables with unknown mapping and run a flat query' do
    get :index, :format => 'xml', :filter => "[[unknown_mapping,begins,'bart']]"

    #puts response.body
    response.should be_success

    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
  end

end
