require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController, 'pagination' do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'returns all record with start=0' do
    get :index, :format => 'xml',
        :sort => 'name',
        :start => 0

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'skips first record with start=1' do
    get :index, :format => 'xml',
        :sort => 'name',
        :start => 1

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'returns two records with limit=2' do
    get :index, :format => 'xml',
        :sort => 'name',
        :limit => 2

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'returns no records with limit=0' do
    get :index, :format => 'xml',
        :sort => 'name',
        :limit => 0

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
      }
    }
  end


  it 'returns correct record with start=1 and limit=1' do
    get :index, :format => 'xml',
        :sort => 'name',
        :start => 1,
        :limit => 1

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
