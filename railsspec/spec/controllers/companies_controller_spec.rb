require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController do

  before(:each) do
  end

  it 'should have introspection capabilities on target model - GET /schema' do
    get :schema, :format => 'xml'
    response.should be_success

    response.body.should be_html_with {
      hash_ {
        type_ 'Company'
        send(:'type-symbolized', 'company')

        id {
          type_ 'integer', :type => :symbol
          primary true, :type => :boolean
          null false, :type => :boolean
          default :nil => :true
        }

        name {
          type_ 'string', :type => :symbol
          primary false, :type => :boolean
          null false, :type => :boolean
          default :nil => :true
        }

        city {
          type_ 'string', :type => :symbol
          primary false, :type => :boolean
          null false, :type => :boolean
          default :nil => :true
        }

        street { }
        zip { }
        send(:'created-at') { }
        send(:'updated-at') { }

        users {
          type_ 'has_many', :type => :symbol
          embedded false, :type => :boolean
          entries(:type => :array) {
          }
        }

        contacts {
          type_ 'has_many', :type => :symbol
          embedded false, :type => :boolean
          entries(:type => :array) {
          }
        }
      }
    }
  end

  it 'should be able to call index' do
    get :index, :format => 'xml'

    response.should be_success

    response.body.should be_html_with {
      company(:type => :array) {
        company {
          city 'NY'
          id_ 1, :type => :integer
          name_ 'big_corp'
          street 'Fifth Avenue'
          zip '28021'
        }
        company {
          city 'Springfield'
          id_ 2, :type => :integer
          name_ 'compuglobal'
          street 'Bart\'s road'
          zip '513'
        }
        company {
          city 'Springfield'
          id_ 3, :type => :integer
          name_ 'newerOS'
          street 'Hill road, 3'
          zip '513'
        }
      }
    }
  end

  it 'should be able to get a record given its ID' do
    get :show, :id => companies(:compuglobal).id,  :format => 'xml'
    response.should be_success

    response.body.should be_html_with {
      company {
        city 'Springfield'
        id_ 2, :type => :integer
        name_ 'compuglobal'
        street 'Bart\'s road'
        zip '513'
      }
    }
  end

  it 'should be able to create a new record' do
    post :create, :format => 'xml',
         :company => {
           :name => 'New Company',
           :city => 'no where'
         }

    response.status.should =~ /^201/
  end

  it 'should be able to reject unknown data while creating a new record' do
    post :create, :format => 'xml',
         :company => {
           :unknown_field => 'oh oh'
         }

    response.status.should =~ /^400/
  end

  it 'should be able to reject invalid data while creating a new record' do
    post :create, :format => 'xml',
         :company => {
           :city => 'no where'
         }

    response.status.should =~ /^406/
    response.should include_text("<company[name]>can't be blank</company[name]>")
  end

  it 'should be able to respect validations checks while creating a new record' do
    post :create, :format => 'xml',
         :company => {
           :name => companies(:compuglobal).name
         }

    response.status.should =~ /^406/
    response.should include_text(" <company[name]>has already been taken</company[name]>")
  end

  it 'should be able to update a record details' do
    put :update, :id => companies(:compuglobal).id, :format => 'xml',
        :company => {
          :name => 'New Compuglobal TM'
        }

    response.status.should =~ /^202/
  end

  it 'should be able to avoid update a record details with unknown data' do
    params = {
    }
    put :update, :id => companies(:compuglobal).id, :format => 'xml',
        :company => {
          :unknown_field => 'oh oh'
        }

    response.status.should =~ /^400/
  end

  it 'should be able to avoid update a record details with invalid data' do
    put :update, :id => companies(:compuglobal).id, :format => 'xml',
        :company => {
          :name => nil,
          :city => 'new location'
        }

    response.status.should =~ /^406/
    response.should include_text("<company[name]>can't be blank</company[name]>")
  end

  it 'should be able to delete a record' do
    id = companies(:compuglobal).id
    delete :destroy, :id => id, :format => 'xml'

    response.should be_success
    get :show, :id => id, :format => 'xml'

    response.should_not be_success
    response.status.should =~ /^404/
  end

  it 'should be able to handle wrong deletion for a record' do
    delete :destroy, :id => 100, :format => 'xml'

    response.should_not be_success
    response.status.should =~ /^404/
  end
end

#
# REST VALIDATIONS
#
describe CompaniesController do

  before(:each) do
  end

#  it 'should be able run a validation ONLY for create action' do
#    post :create, :format => 'xml',
#         :company => {
#           :name => 'Brand new PRO company'
#         },
#         :_only_validation => :true
#
#    response.status.should =~ /^202/
#
#    # check the full list
#    get :index,  :format => 'xml'
#    response.should_not include_text('<name>Brand new PRO company</name>')
#  end
#
#  it 'should be able run a validation ONLY for update action' do
#    params = {
#      :name => 'Renamed to Compuglobal TM'
#    }
#    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company => params, :_only_validation => :true
#    response.status.should == STATUS[:s202]
#
#    # try to read - the value must be the previous
#    get :show, :id => companies(:compuglobal).id, :format => 'xml'
#    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
end


##
## EXT JS - upload form
##
#class BasicFeaturesExtJSUploadController < ApplicationController
#  layout false
#  rest_controller_for Company
#end
#
#describe BasicFeaturesExtJSUploadController do
#
#  set_fixture_class :companies => Company
#  fixtures :companies
#
#  before(:each) do
#  end
#
#  it 'should change response status when handling with extjs invalid data on create action' do
#    params= { :city => 'no where' }
#    post :create, :format => 'xml', :company => params
#    response.should be_success # 200 OK - but we got errors
#
#    response.body.should include_text("<company[name]>can't be blank</company[name]>")
#  end
#
#  it 'should change response status when handling with extjs invalid data on update action' do
#    params= {
#      :name => nil,
#      :city => 'no where'
#    }
#    put :update, :id => 1, :format => 'xml', :company => params
#
#    response.should be_success # 200 OK - but we got errors
#    response.body.should include_text("<company[name]>can't be blank</company[name]>")
#  end
#end
