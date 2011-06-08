#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class FinderAutoController < ActionController::Base
  layout false
  rest_controller_for Company, :index_options => { :finder => :auto }
end

describe FinderAutoController do

  set_fixture_class :companies => Company
  fixtures :companies
  set_fixture_class :users => User
  fixtures :users
  set_fixture_class :contacts => Contact
  fixtures :contacts


  before(:each) do
  end

  it 'should use the basic finder' do
    get :index, :format => 'xml', :fields => '[name,city]', :like => '[tm,spring]', :jc => 'OR', :basic => true

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should use the arithmetical finder' do
    get :index, :format => 'xml', :filter => '[[id,gt,1]]'

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should use fallback to empty conditions when no suitable finder is found' do
    get :index, :format => 'xml', :unknown_filter => 'search_this'

    response.should be_success

    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

end
