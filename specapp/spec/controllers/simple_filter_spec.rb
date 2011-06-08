require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController, 'simple filter' do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'filters records' do
    get :index, :format => 'xml',
        :name => 'compuglobal'

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

end
