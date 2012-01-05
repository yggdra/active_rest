require 'spec_helper'

require 'assert2/xhtml'

describe VirtattrCompaniesController, 'get' do

  before(:each) do
    @c1 = Factory(:company_complex)
    get :show, :id => @c1.id,  :format => 'json'
  end

  it 'returns a valid response to GET' do
    response.should be_success
    response.status.should == 200
  end

  it 'responds to GET with embedded attributes' do
    b = ActiveSupport::JSON.decode(response.body)

    b.should include('location')

    b['location'].should include('lon')

    b.should include('phones')
    b['phones'][0].should include('number' => '99999999')
  end

  it 'responds to GET with virtual attributes' do
    b = ActiveSupport::JSON.decode(response.body)

    b.should include('upcase_name' => 'HUGE CORP CORP.')
    b['location'].should include('elevation' => 100)
    b['phones'][0].should include('dashed_number' => '9-9-9-9-9-9-9-9')
  end
end

describe VirtattrCompaniesController, 'schema' do
  before(:each) do
    @c1 = Factory(:company_complex)
    get :schema, :id => @c1.id,  :format => 'json'
  end

  it 'includes model\'s human name' do
    b = ActiveSupport::JSON.decode(response.body)

    b['attrs']['name'].should include('human_name' => 'Nome')
  end
end
