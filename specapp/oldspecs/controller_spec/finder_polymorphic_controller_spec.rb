#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__)+ '/../models/company')
require File.expand_path(File.dirname(__FILE__)+ '/../models/user')
require File.expand_path(File.dirname(__FILE__)+ '/../models/contact')

class FinderPolymorphicController < ActionController::Base
  layout false
  ar_controller_for Contact, :index_options => {
            :finder => :polymorphic,
            :polymorphic => {
                          :filter_field => :my_filter_name,
                          :select=>
                            [{:table_name => 'active_rest_companies',
                              :fields => [:name], # array
                              :join_id => :owner_id,
                              :join_type => :owner_type,
                              :join_value => 'Company'},
                             {:table_name => 'active_rest_users',
                              :fields => :name, # without array
                              :join_id => :owner_id,
                              :join_type => :owner_type,
                              :join_value => 'User'}
                            ]
                          }
            } # eo index_options
end

describe FinderPolymorphicController do

  set_fixture_class :companies => Company
  fixtures :companies
  set_fixture_class :users => User
  fixtures :users
  set_fixture_class :contacts => Contact
  fixtures :contacts


  before(:each) do
  end

  it 'should run a flat query when no parameter are passed' do
    get :index, :format => 'xml'

    response.should be_success
    response.should include_text('<id type="integer">' + contacts(:bart_tel).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:compulglobal_email).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:homer_fax).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:marge_tel).id.to_s + '</id>')
  end

  it 'should map the polymorphic filter (1)' do
    get :index, :format => 'xml', :fields => '[my_filter_name]', :like => '[sim]'

    response.should be_success
    response.should include_text('<id type="integer">' + contacts(:bart_tel).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:homer_fax).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:marge_tel).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:compulglobal_email).id.to_s + '</id>')
  end

  it 'should map the polymorphic filter (2)' do
    get :index, :format => 'xml', :fields => '[my_filter_name]', :like => '[com]'

    response.should be_success
    response.should_not include_text('<id type="integer">' + contacts(:bart_tel).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:homer_fax).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:marge_tel).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:compulglobal_email).id.to_s + '</id>')
  end

  it 'should map the polymorphic filter AND search on target_model field' do
    get :index, :format => 'xml', :fields => '[field,my_filter_name]', :like => '[fax,sim]', :jc => 'AND'

    response.should be_success
    response.should include_text('<id type="integer">' + contacts(:homer_fax).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:bart_tel).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:bart_tel).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:compulglobal_email).id.to_s + '</id>')
  end

  it 'should map the polymorphic filter OR search on target_model field' do
    get :index, :format => 'xml', :fields => '[field,my_filter_name]', :like => '[tel,sim]' #, :jc => 'OR'

    response.should be_success
    response.should include_text('<id type="integer">' + contacts(:bart_tel).id.to_s + '</id>')
    response.should include_text('<id type="integer">' + contacts(:marge_tel).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:homer_fax).id.to_s + '</id>')
    response.should_not include_text('<id type="integer">' + contacts(:compulglobal_email).id.to_s + '</id>')
  end

end
