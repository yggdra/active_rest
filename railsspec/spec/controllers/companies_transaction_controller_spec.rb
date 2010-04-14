require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesTransactionController do

  before(:each) do
  end

  it 'should be able to create a new record' do
    post :create, :format => 'xml',
         :company => {
           :name => 'New Company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }

    response.status.should == 201
  end
end
