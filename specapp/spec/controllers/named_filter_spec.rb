require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController, 'named filter' do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
    @c2 = FactoryGirl.create(:company_2)
    @c3 = FactoryGirl.create(:company_3)
  end

  it 'rejects unknown filters' do
    get :index, :format => :json,
        :filter => 'nonexistant'

    response.should_not be_success
    response.status.should == 400
  end

  it 'applies filter with symbol parameter' do
    get :index, :format => :json,
        :filter => 'filter1'

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b[0].should deep_include({ 'id' => 1 })
    b[1].should be_nil
  end

  it 'applies filter with hash parameter' do
    get :index, :format => :json,
        :filter => 'filter2'

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b[0].should deep_include({ 'id' => 2 })
    b[1].should be_nil
  end

  it 'applies filter with block parameter' do
    get :index, :format => :json,
        :filter => 'filter3', :foobar => 3

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b[0].should deep_include({ 'id' => 3 })
    b[1].should be_nil
  end

  it 'applies multiple filters' do
    get :index, :format => :json,
        :filter => 'filter1,filter3', :foobar => 1

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b[0].should deep_include({ 'id' => 1 })
    b[1].should be_nil
  end

  it 'applies multiple filters' do
    get :index, :format => :json,
        :filter => 'filter1,filter3', :foobar => 3

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b[0].should be_nil
  end

end
