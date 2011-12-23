require 'spec_helper'

require 'assert2/xhtml'

describe InclattrCompaniesController, 'get' do

  before(:each) do
    @c1 = Factory(:company_complex)
    get :show, :id => @c1.id,  :format => 'json'
  end

  it 'returns a valid response to GET' do
    response.should be_success
    response.status.should == 200
  end

  it 'responds to GET with included attributes' do
    b = ActiveSupport::JSON.decode(response.body)

    b.should include('group')

    b['group'].should be_a(Hash)
    b['group'].should include('name' => 'MegaHolding')
  end
end
