require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController, 'json filter' do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'fails for unexistant attribute' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'foobar' }, :o => '>', :b => 1 }.to_json

    response.should_not be_success
    response.status.should == 400
  end

  it 'filters records with condition >' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => '>', :b => 1 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'filters records with condition >=' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => '>=', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'filters records with condition <' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => '<', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'filters records with condition < on datetimes' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'registration_date' }, :o => '<', :b => '2012-12-12' }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'filters records with condition <=' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => '<=', :b => 1 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'filters records with condition =' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => '=', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'filters records with condition <>' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => '<>', :b => 2 }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'filters records with condition IS NULL' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => 'IS NULL' }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company }
      }
    }
  end

  it 'filters records with condition IS NOT NULL' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => 'IS NOT NULL' }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'filters records with condition IN [array]' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => 'IN', :b => [1,3] }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        without! { company { name_ 'compuglobal' } }
        company { name_ 'newerOS' }
      }
    }
  end

  it 'filters records with condition NOT IN [array]' do
    get :index, :format => 'xml',
        :filter => { :a => { :field => 'id' }, :o => 'NOT IN', :b => [1,3] }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

#### Not supported by SQLite
#  it 'filters records with boolean condition' do
#    get :index, :format => 'xml',
#        :filter => { :field => 'is_active' }.to_json
#
#    response.should be_success
#
#    response.body.should be_xml_with {
#      companies(:type => :array) {
#        without! { company { name_ 'big_corp' } }
#        company { name_ 'compuglobal' }
#        without! { company { name_ 'newerOS' } }
#      }
#    }
#  end

  it 'filters records with complex condition' do
    get :index, :format => 'xml',
        :filter => { :a => { :a => { :a => { :field => 'id' }, :o => '<', :b => 3 },
                              :o => 'AND',
                              :b => { :a => { :field => 'id' }, :o => '>', :b => 1 } },
                      :o => 'OR',
                      :b => { :a => { :field => 'name' },
                              :o => 'ILIKE',
                              :b => '%corp%' } }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company { name_ 'big_corp' }
        company { name_ 'compuglobal' }
        without! { company { name_ 'newerOS' } }
      }
    }
  end

  it 'filters records with conditions on joined relations' do
    @cc = Factory(:company_complex)

    get :index, :format => 'xml',
        :filter => { :a => { :field => 'location.raw_name' },
                     :o => 'ILIKE',
                     :b => '%Seveso%' }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
        company { name_ 'Huge Corp Corp.' }
      }
    }
  end

  it 'filters records with condition on joined relation' do
    @cc = Factory(:company_complex)

    get :index, :format => 'xml',
        :filter => { :a => { :field => 'location.raw_name' },
                     :o => 'ILIKE',
                     :b => '%dsfgkjdshgkdshkdsfj%' }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        without! { company { name_ 'compuglobal' } }
        without! { company { name_ 'newerOS' } }
        without! { company { name_ 'BigCorp' } }
      }
    }
  end

  it 'filters records with conditions on both joined relation and the record itself' do
    @cc = Factory(:company_complex)

    get :index, :format => 'xml',
        :filter => { :a => { :a => { :field => 'location.raw_name' },
                             :o => 'ILIKE',
                             :b => '%Seveso%' },
                     :o => 'OR',
                     :b => { :a => { :field => 'city' },
                             :o => '=',
                             :b => 'Springfield' } }.to_json

    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        without! { company { name_ 'big_corp' } }
        company { name_ 'compuglobal' }
        company { name_ 'newerOS' }
        company { name_ 'Huge Corp Corp.' }
      }
    }
  end

end
