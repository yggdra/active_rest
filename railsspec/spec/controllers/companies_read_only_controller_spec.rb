require 'spec_helper'

require 'assert2/xhtml'

#
# CONTROLLER IN READ ONLY MODE
#
describe CompaniesReadOnlyController do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'should allow index action' do
    get :index, :format => 'xml'
    response.should be_success

    response.body.should be_xml_with {
      company(:type => :array) {
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

  it 'should allow get a user by its ID' do
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

  it 'should NOT allow POST action' do
    post :create, :format => 'xml',
         :company => { :name => 'Zorro' }
    response.status.should == 405
  end

  it 'should NOT allow PUT action' do
    post :update, :id => @c2.id, :format => 'xml',
         :company => { :name => 'Microsort' }
    response.status.should == 405
  end

  it 'should NOT allow delete action' do
    delete :destroy, :id => @c2.id, :format => 'xml'
    response.status.should == 405
  end
end
