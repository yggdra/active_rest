require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'should fail for unexistant attribute' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'foobar' }, :o => '>', :b => 1 }.to_json

    response.should_not be_success
    response.status.should == 400
  end

  it 'should find records with finder condition >' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => '>', :b => 1 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'should find records with finder condition >=' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => '>=', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'should find records with finder condition <' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => '<', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'should find records with finder condition <=' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => '<=', :b => 1 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'should find records with finder condition =' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => '=', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'should find records with finder condition <>' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => '<>', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'should find records with finder condition IS NULL' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => 'IS NULL' }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        without! { company }
      }
    }
  end

## Not yet supported by Arel? FIXME TODO
#  it 'should find records with finder condition IS NOT NULL' do
#    get :index, :format => 'xml',
#        :_filter => { :a => { :field => 'id' }, :o => 'IS NOT NULL' }.to_json
#
#    response.should be_success
#
#    response.body.should be_xml_with {
#      company(:type => :array) {
#        company { name_ 'big_corp' }
#        company { name_ 'compuglobal' }
#        company { name_ 'newerOS' }
#      }
#    }
#  end

  it 'should find records with finder condition IN [array]' do
    get :index, :format => 'xml',
        :_filter => { :a => { :field => 'id' }, :o => 'IN', :b => [1,3] }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        company { name_ 'newerOS' }
      }
    }
  end

## Not yet supported by Arel? FIXME TODO
#  it 'should find records with finder condition NOT IN [array]' do
#    get :index, :format => 'xml',
#        :_filter => { :a => { :field => 'id' }, :o => 'NOT IN', :b => [1,3] }.to_json
#
#    response.should be_success
#
#    response.body.should be_xml_with {
#      company(:type => :array) {
#        without! { company { name_ 'big_corp' } }
#        company { name_ 'compuglobal' }
#        without! { company { name_ 'newerOS' } }
#      }
#    }
#  end

#### Not supported by SQLite
#  it 'should find records with finder boolean condition' do
#    get :index, :format => 'xml',
#        :_filter => { :field => 'is_active' }.to_json
#
#    response.should be_success
#
#    response.body.should be_xml_with {
#      company(:type => :array) {
#        without! { company { name_ 'big_corp' } }
#        company { name_ 'compuglobal' }
#        without! { company { name_ 'newerOS' } }
#      }
#    }
#  end

  it 'should find records with complex finder condition' do
    get :index, :format => 'xml',
        :_filter => { :a => { :a => { :a => { :field => 'id' }, :o => '<', :b => 3 },
                              :o => 'AND',
                              :b => { :a => { :field => 'id' }, :o => '>', :b => 1 } },
                      :o => 'OR',
                      :b => { :a => { :field => 'name' },
                              :o => 'LIKE',
                              :b => '%corp%' } }.to_json

    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
        company { name_ 'big_corp' }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

end

#
##
## FINDER with joins - no remapping
##
#class FinderOperatorsWJController < ActionController::Base
#  layout false
#  rest_controller_for Company, :index_options => { :finder => :Operators },
#                               :model_options => { :join => { :users => true } }
#end
#describe FinderOperatorsWJController do
#
#  set_fixture_class :companies => Company
#  fixtures :companies
#  set_fixture_class :users => User
#  fixtures :users
#
#  before(:each) do
#  end
#
#  it 'should map arguments to joins tables correctly' do
#    get :index, :format => 'xml', :_filter => "[['users[id]',gt,3]]"
#
#    #puts response.body
#    response.should be_success
#
#    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
#    response.should_not include_text('<name>' + companies(:newerOS).name + '</name>')
#    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
#    response.should include_text('<users-name type="">' + users(:maggie_simpson).name + '</users-name>')
#  end
#
#  it 'should fallback to target_model field correctly (1)' do
#    get :index, :format => 'xml', :_filter => "[[id,gt,2]]"
#
#    response.should be_success
#
#    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
#    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
#
#    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
#    response.should include_text('<users-name type="">' + users(:marge_simpson).name + '</users-name>')
#    response.should include_text('<users-name type="">' + users(:bart_simpson).name + '</users-name>')
#  end
#
#
#  it 'should fallback to target_model field correctly (2)' do
#    get :index, :format => 'xml', :_filter => "[['company[id]',gt,2]]"
#
#    response.should be_success
#
#    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
#    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
#
#    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
#    response.should include_text('<users-name type="">' + users(:marge_simpson).name + '</users-name>')
#    response.should include_text('<users-name type="">' + users(:bart_simpson).name + '</users-name>')
#  end
#
#  it 'should fallback to target_model field correctly (2)' do
#    get :index, :format => 'xml', :_filter => "[['users_id',gt,2]]"
#
#    #puts response.body
#    response.should be_success
#
#    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
#
#    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
#    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
#    response.should include_text('<users-name type="">' + users(:marge_simpson).name + '</users-name>')
#    response.should include_text('<users-name type="">' + users(:maggie_simpson).name + '</users-name>')
#  end
#end
#
##
## FINDER with joins - yes remapping
##
#class FinderOperatorsWJoinAndMappingController < ActionController::Base
#  layout false
#  rest_controller_for Company, :index_options => {:finder => :Operators},
#  :model_options => { :join => { :users => { :name => 'my_name'} } }
#end
#describe FinderOperatorsWJoinAndMappingController do
#
#  set_fixture_class :companies => Company
#  fixtures :companies
#  set_fixture_class :users => User
#  fixtures :users
#
#  before(:each) do
#  end
#
#  it 'should map arguments to joins tables correctly' do
#    get :index, :format => 'xml', :_filter => "[[my_name,begins,'bart']]"
#
#    #puts response.body
#    response.should be_success
#
#    response.should_not include_text('<name>' + companies(:big_corp).name + '</name>')
#    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
#
#    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
#    response.should include_text('<my-name type="">' + users(:bart_simpson).name + '</my-name>')
#  end
#
#  it 'should not map arguments to joins tables with unknown mapping and run a flat query' do
#    get :index, :format => 'xml', :_filter => "[[unknown_mapping,begins,'bart']]"
#
#    #puts response.body
#    response.should be_success
#
#    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
#    response.should include_text('<name>' + companies(:compuglobal).name + '</name>')
#    response.should include_text('<name>' + companies(:newerOS).name + '</name>')
#  end
#
#end
