#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../models/company')
require File.expand_path(File.dirname(__FILE__) + '/../models/user')
require File.expand_path(File.dirname(__FILE__) + '/../models/contact')

class ReadOnlyController < ActionController::Base
  layout false
  ar_controller_for User, :read_only => true
end

#
# CONTROLLER IN READ ONLY MODE
#
describe ReadOnlyController do

  before(:each) do
  end

  set_fixture_class :users => User
  fixtures :users

  before(:each) do
  end

  it 'should be allow index action' do
    get :index, :format => 'xml'
    response.should be_success

    # check the full list
    response.should include_text('<name>' + users(:bart_simpson).name + '</name>')
    response.should include_text('<name>' + users(:homer_simpson).name + '</name>')
    response.should include_text('<name>' + users(:marge_simpson).name + '</name>')
    response.should include_text('<name>' + users(:maggie_simpson).name + '</name>')
    response.should include_text('<name>' + users(:lisa_simpson).name + '</name>')
  end

  it 'should allow get a user by its ID' do
    get :show, :id => users(:bart_simpson).id, :format => 'xml'
    response.should be_success

    response.should include_text('<name>' + users(:bart_simpson).name + '</name>')
  end

  it 'should NOT allow post action' do
    params = { :name => 'Zorro' }
    post :create, :format => 'xml', :user => params
    response.status.should == STATUS[:s405]
  end

  it 'should NOT allow put action' do
    params = { :name => 'Bart alias Zorro' }
    post :create, :id => users(:bart_simpson).id, :format => 'xml', :user => params
    response.status.should == STATUS[:s405]
  end

  it 'should NOT allow delete action' do
    delete :destroy, :id => users(:bart_simpson).id, :format => 'xml', :user => params
    response.status.should == STATUS[:s405]
  end
end
