
require 'spec_helper'

describe CompaniesController do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'sorts ascending on a single field without +' do
    get :index, :format => :json, :sort => 'name'

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should deep_include([
      { 'id' => 1 },
      { 'id' => 2 },
      { 'id' => 3 },
    ])
  end

  it 'sorts ascending on a single field with +' do
    pending
  end

  it 'sorts descending on a single field with -' do
    pending
  end

  it 'sorts ascending a multiple fields' do
    pending
  end

end
