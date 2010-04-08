require 'spec_helper'

require 'assert2/xhtml'

#
# CONTROLLER IN READ ONLY MODE
#
describe CompaniesReadOnlyController do

  before(:each) do
  end

  it 'should allow index action' do
    get :index, :format => 'xml'
    response.should be_success

    response.body.should be_html_with {
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
    get :show, :id => companies(:compuglobal).id,  :format => 'xml'
    response.should be_success

    response.body.should be_html_with {
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
    response.status.should =~ /^405/
  end

  it 'should NOT allow PUT action' do
    post :update, :id => companies(:compuglobal).id, :format => 'xml',
         :company => { :name => 'Microsort' }
    response.status.should =~ /^405/
  end

  it 'should NOT allow delete action' do
    delete :destroy, :id => users(:bart_simpson).id, :format => 'xml', :user => params
    response.status.should =~ /^405/
  end
end
