#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../models/company')
require File.expand_path(File.dirname(__FILE__) + '/../models/user')
require File.expand_path(File.dirname(__FILE__) + '/../models/contact')

class IndexExtraConditionsController < ActionController::Base
  layout false

  #
  # NOTE - actually only the basic finder support this feature
  #
  ar_controller_for Company, :index_options => { :extra_conditions => :append_my_conditions, :finder => :basic }

  def append_my_conditions
    { :id => 3 } # force to find id 3 - maybe a runtime value :-p
  end
end

describe IndexExtraConditionsController do

  set_fixture_class :companies => Company
  fixtures :companies

  before(:each) do
  end

  it 'should find only record with the designated id' do
    get :index, :format => 'xml'

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
  end


  it 'should override with the parameter declared in extra_conditions' do
    get :index, :format => 'xml', :fields => '[id]', :query => '1'

    response.should be_success

    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')

    response.should include_text('<name>' + companies(:newerOS).name + '</name>') # return the default (id=3)
  end

  it 'should run a query filter adding extra conditions' do
    get :index, :format => 'xml', :fields => '[city]', :query => 'nowhere'

    response.should be_success

    # no matching record for this query
    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
    response.should_not include_text('<name>' + companies(:newerOS).name + '</name>')
  end

  it 'should run a query filter adding extra conditions' do
    get :index, :format => 'xml', :fields => '[city]', :query => 'Springfield'

    response.should be_success

    # matching record for this query
    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
  end
end
