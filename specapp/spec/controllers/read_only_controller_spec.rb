require 'spec_helper'

require 'assert2/xhtml'

#
# CONTROLLER IN READ ONLY MODE
#
describe ReadOnlyCompaniesController do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
    @c2 = FactoryGirl.create(:company_2)
    @c3 = FactoryGirl.create(:company_3)
  end

  it 'allows GET / verb' do
    get :index, :format => :json
    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 1, 'name' => 'big_corp' },
      { 'id' => 2, 'name' => 'compuglobal' },
      { 'id' => 3, 'name' => 'newerOS' },
    ])
  end

  it 'allows GET verb with an ID' do
    get :show, :id => @c2.id,  :format => :json
    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include({
      'city' => 'Springfield',
      'id' => 2,
      'name' => 'compuglobal',
      'street' => 'Bart\'s road',
      'zip' => '513',
    })
  end

  it 'disallows POST verb' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :name => 'New Company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }.to_json

    post :create, :format => :json

    response.status.should == 405
  end

  it 'disallows PUT verb' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :name => 'New Company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }.to_json

    put :update, :id => @c2.id, :format => :json

    response.status.should == 405
  end

  it 'disallows DELETE verb' do
    delete :destroy, :id => @c2.id, :format => :json
    response.status.should == 405
  end
end
