require 'spec_helper'

require 'assert2/xhtml'

#
# CONTROLLER IN READ ONLY MODE
#
describe ReadOnlyCompaniesController do

  before(:each) do
    @c1 = Factory.create(:company_1)
    @c2 = Factory.create(:company_2)
    @c3 = Factory.create(:company_3)
  end

  it 'allows GET / verb' do
    pending
    get :index, :format => 'xml'
    response.should be_success

    response.body.should be_xml_with {
      companies(:type => :array) {
        company {
          id_ 1, :type => :integer
          name_ 'big_corp'
        }
        company {
          id_ 2, :type => :integer
          name_ 'compuglobal'
        }
        company {
          id_ 3, :type => :integer
          name_ 'newerOS'
        }
      }
    }
  end

  it 'allows GET verb with an ID' do
    pending
    get :show, :id => @c2.id,  :format => 'xml'
    response.should be_success

    response.body.should be_xml_with {
      company {
        city 'Springfield'
        id_ 2, :type => :integer
        name_ 'compuglobal'
        street 'Bart\'s road'
        zip '513'
      }
    }
  end

  it 'disallows POST verb' do
    pending
    post :create, :format => 'xml',
         :company => { :name => 'Zorro' }
    response.status.should == 405
  end

  it 'disallows PUT verb' do
    pending
    post :update, :id => @c2.id, :format => 'xml',
         :company => { :name => 'Microsort' }
    response.status.should == 405
  end

  it 'disallows DELETE verb' do
    pending
    delete :destroy, :id => @c2.id, :format => 'xml'
    response.status.should == 405
  end
end
