
require 'spec_helper'

describe CompaniesController do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
    @c2 = FactoryGirl.create(:company_2)
    @c3 = FactoryGirl.create(:company_3)
  end

  it 'sorts ascending on a single field without +' do
    get :index, :format => :json, :sort => 'name'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 1 },
      { 'id' => 2 },
      { 'id' => 3 },
    ])
  end

  it 'sorts ascending on a single field with +' do
    get :index, :format => :json, :sort => '+name'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 1 },
      { 'id' => 2 },
      { 'id' => 3 },
    ])
  end

  it 'sorts descending on a single field with -' do
    get :index, :format => :json, :sort => '-name'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 3 },
      { 'id' => 2 },
      { 'id' => 1 },
    ])
  end

  it 'sorts ascending a multiple fields' do
    get :index, :format => :json, :sort => '+is_active,+id'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 2 },
      { 'id' => 1 },
      { 'id' => 3 },
    ])
  end

  it 'sorts ascending on a nested field without +' do
    get :index, :format => :json, :sort => 'location.raw_name'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 2 },
      { 'id' => 3 },
    ])
  end

  it 'sorts ascending on a nested field with +' do
    get :index, :format => :json, :sort => '+location.raw_name'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 2 },
      { 'id' => 3 },
    ])
  end

  it 'sorts descending on a nested field with -' do
    get :index, :format => :json, :sort => '-location.raw_name'

    response.should be_success

    ActiveSupport::JSON.decode(response.body).should deep_include([
      { 'id' => 3 },
      { 'id' => 2 },
    ])
  end

end
