#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class BasicFeaturesController < ActionController::Base
  layout false
  rest_controller_for Company, :index_options => { :finder => :basic }
end

#
# INSPECTORS
#
describe BasicFeaturesController do

  before(:each) do
  end

  it 'should have introspection capabilities on target model  - schema' do
    get :schema, :format => 'xml'
    response.should be_success

    # schema
    response.should include_text('<schema type="array">')
    response.should include_text('<id>')
    response.should include_text('<name>')
    response.should include_text('<city>')
    response.should include_text('<street>')
    response.should include_text('<zip>')
    response.should include_text('<users>')
    response.should include_text('<contacts>')

    # model key
    response.should include_text('<type>Company</type>')
    response.should include_text('<type_symbolized>company</type_symbolized>')
  end
end


#
# REST ACTIONS
#
describe BasicFeaturesController do

  set_fixture_class :companies => Company
  fixtures :companies

  set_fixture_class :users => User
  fixtures :users

  set_fixture_class :contacts => Contact
  fixtures :contacts

  before(:each) do
  end

  it 'should be able to call index' do
    get :index, :format => 'xml'

    response.should be_success

    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should be able to get a record given its ID' do
    get :show, :id => companies(:compuglobal).id,  :format => 'xml'
    response.should be_success

    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

  it 'should be able to create a new record' do
    params= {
      :name => 'New Company',
      :city => 'no where'
    }
    post :create, :format =>'xml', :company => params
    response.status.should == STATUS[:s201]
  end

  it 'should be able to reject unknown data while creating a new record' do
    params= {
      :unknown_field => 'oh oh'
    }
    post :create, :format =>'xml', :company => params
    response.status.should == STATUS[:s400]
  end

  it 'should be able to reject invalid data while creating a new record' do
    params= {
      :city => 'no where'
    }
    post :create, :format =>'xml', :company => params

    response.status.should == STATUS[:s406]
    response.should include_text("<company[name]>can't be blank</company[name]>")
  end

  it 'should be able to respect validations checks while creating a new record' do
    params= {
      :name => companies(:compuglobal).name
    }
    post :create, :format => 'xml', :company => params

    response.status.should == STATUS[:s406]
    response.should include_text(" <company[name]>has already been taken</company[name]>")
  end

  it 'should be able to update a record details' do
    params = {
      :name => 'New Compuglobal TM'
    }

    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company => params

    response.status.should == STATUS[:s202]
  end

  it 'should be able to avoid update a record details with unknown data' do
    params = {
      :unknown_field => 'oh oh'
    }
    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company => params

    response.status.should == STATUS[:s400]
  end

  it 'should be able to avoid update a record details with invalid data' do
    params = {
      :name => nil,
      :city => 'new location'
    }
    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company => params

    response.status.should == STATUS[:s406]
    response.should include_text("<company[name]>can't be blank</company[name]>")
  end

  it 'should be able to delete a record' do
    id =companies(:compuglobal).id
    delete :destroy, :id => id, :format => 'xml'

    response.should be_success
    get :show, :id => id, :format => 'xml'

    response.should_not be_success
    response.status.should == STATUS[:s404]
  end

  it 'should be able to handle wrong deletion for a record' do
    delete :destroy, :id => 100, :format => 'xml'

    response.should_not be_success
    response.status.should == STATUS[:s404]
  end
end


#
# REST VALIDATIONS
#
describe BasicFeaturesController do

  set_fixture_class :companies => Company
  fixtures :companies

  before(:each) do
  end

  it 'should be able run a validation ONLY for create action' do
    params = {
      :name => 'Brand new PRO company'
    }
    post :create, :format => 'xml', :company => params, :_only_validation => :true

    response.status.should == STATUS[:s202]

    # check the full list
    get :index,  :format => 'xml'
    response.should_not include_text('<name>Brand new PRO company</name>')
  end

  it 'should be able run a validation ONLY for update action' do
    params = {
      :name => 'Renamed to Compuglobal TM'
    }
    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company => params, :_only_validation => :true
    response.status.should == STATUS[:s202]

    # try to read - the value must be the previous
    get :show, :id => companies(:compuglobal).id, :format => 'xml'
    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
  end
end


#
# EXT JS - upload form
#
class BasicFeaturesExtJSUploadController < ApplicationController
  layout false
  rest_controller_for Company
end

describe BasicFeaturesExtJSUploadController do

  set_fixture_class :companies => Company
  fixtures :companies

  before(:each) do
  end

  it 'should change response status when handling with extjs invalid data on create action' do
    params= { :city => 'no where' }
    post :create, :format => 'xml', :company => params
    response.should be_success # 200 OK - but we got errors

    response.body.should include_text("<company[name]>can't be blank</company[name]>")
  end

  it 'should change response status when handling with extjs invalid data on update action' do
    params= {
      :name => nil,
      :city => 'no where'
    }
    put :update, :id => 1, :format => 'xml', :company => params

    response.should be_success # 200 OK - but we got errors
    response.body.should include_text("<company[name]>can't be blank</company[name]>")
  end
end
