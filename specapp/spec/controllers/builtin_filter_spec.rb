require 'spec_helper'

describe CompaniesController, 'built-in filters' do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'filters records with basic where relation' do
    get :index, :format => 'xml',
        :flt => :simple_filter

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'filters records with lambda relation' do
    pending
  end

  it 'filters records with lambda relation and external parameter' do
    pending
  end

  it 'uses :default filter if nothing specified' do
    pending
  end
end
