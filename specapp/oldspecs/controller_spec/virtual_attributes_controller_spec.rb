#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../models/company')
require File.expand_path(File.dirname(__FILE__) + '/../models/user_virtual_attrs') #only with basic finder (right now)

class VirtualAttributesController < ActionController::Base
  layout false
  rest_controller_for UserVirtualAttrs
end


#
# INSPECTORS now can present virtual columns
#
describe VirtualAttributesController do
  before(:each) do
  end

  it 'should have introspection capabilities even for virtual column on target model  - schema' do
    get 'schema', :format => 'xml'
    response.should be_success

    # schema
    response.should include_text('<name type="symbol">company_label</name>')
    response.should include_text('<virtual type="boolean">true</virtual>')
  end
end


#
# INDEX with virtual columns
#
describe VirtualAttributesController do

  set_fixture_class :companies => Company
  fixtures :companies
  set_fixture_class :users => UserVirtualAttrs
  fixtures :users

  before(:each) do
  end

  it 'should describe virtual attributes' do
    get :index, :format => 'xml'

    response.should be_success

    response.should have_tag("company-label", companies(:newerOS).name, :xml => true)
    response.should have_tag("company-label", companies(:big_corp).name, :xml => true)
    response.should have_tag("company-label", companies(:compuglobal).name, :xml => true)

  end

  it 'should find querying with virtual column' do
    get :index, :format => 'xml', :fields => '[company_label]', :like => '[big]'

    response.should be_success

    response.should have_tag("name", users(:homer_simpson).name, :xml => true)
    response.should have_tag('company-label', companies(:big_corp).name, :xml => true)
    response.should_not have_tag('company-label', companies(:newerOS).name, :xml => true)
    response.should_not have_tag('company-label', companies(:compuglobal).name, :xml => true)
  end

  it 'should not run query including unknown virtual columns' do
    get :index, :format => 'xml', :fields => '[search_me]', :like => '[hello]'

    response.should be_success

    #puts response.body
    response.should_not include_text('hello') # find a way to check this on result...
  end

  it 'should find query with real field' do
    get :index, :format => 'xml', :fields => '[company_id]', :like => "[#{companies(:big_corp).id}]"

    response.should be_success

    response.should have_tag("name", users(:homer_simpson).name, :xml => true)
    response.should have_tag('company-label', companies(:big_corp).name, :xml => true)
    response.should_not have_tag('company-label', companies(:newerOS).name, :xml => true)
    response.should_not have_tag('company-label', companies(:compuglobal).name, :xml => true)
  end
end
