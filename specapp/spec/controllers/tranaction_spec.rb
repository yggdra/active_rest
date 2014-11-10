require 'spec_helper'

require 'assert2/xhtml'

describe TransactionCompaniesController, type: :controller do

  before(:each) do
  end

  it 'creates a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :name => 'New Company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }.to_json

    post :create, :format => 'xml'

    response.status.should == 201
  end
end
