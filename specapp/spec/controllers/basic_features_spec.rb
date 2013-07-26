require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
    @c2 = FactoryGirl.create(:company_2)
    @c3 = FactoryGirl.create(:company_3)
  end

  it 'returns model\'s schema with GET /schema' do
    get 'schema', :format => :json
    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should deep_include({
      'type' => 'Company',
      'attrs' => {
        'id' => { 'type' => 'integer' },
        'created_at' => { 'type' => 'timestamp' },
        'updated_at' => { 'type' => 'timestamp' },
        'name' => { 'type' => 'string', 'human_name' => 'Nome' },
        'full_address' => {
          'city' => { 'type' => 'string' },
          'street' => {'type' => 'string' },
          'zip' => {'type' => 'string' },
        },
        'is_active' => {'type' => 'boolean' },
        'registration_date' => {'type' => 'timestamp' },
        'group_id' => { 'type' => 'integer' },
        'users' => { 'type' => 'uniform_references_collection', 'referenced_class' => 'User' },
        'contacts' => { 'type' => 'uniform_references_collection' },
        'group' => { 'type' => 'reference', 'referenced_class' => 'Group' },
        'phones' => {
          'type' => 'uniform_models_collection',
          'human_name' => 'Phone numbers',
          'schema' => {
            'type' => 'Company::Phone',
            'attrs' => {
               'id' => { 'type' => 'integer' },
               'company_id' => { 'type' => 'integer' },
               'number' => { 'type' => 'string' },
              'company' => { 'type' => 'reference', 'referenced_class' => 'Company'}
            },
            'object_actions' => { 'read' => {}, 'write' => {}, 'delete' => {} },
            'class_actions' => { 'create' => {} },
            'class_perms' => { 'create' => true }
          },
        },
        'location' => {
          'type' => 'embedded_model',
          'schema' => {
            'type' => 'CompanyLocation',
            'attrs' => {
              'id' => { 'type' => 'integer' },
              'lat' => { 'type' => 'float' },
              'lon' => { 'type' => 'float' },
              'raw_name' => { 'type' => 'string' },
              'companies' => {
                'type' => 'uniform_references_collection',
                'referenced_class' => 'Company'
              }
            },
            'object_actions' => { 'read' => {}, 'write' => {}, 'delete' => {} },
            'class_actions' => { 'create' => {} },
            'class_perms' => { 'create' => true}
          }
        },
        'full_address' => { 'type' => 'structure' },
        'object_1' => { 'type' => 'embedded_polymorphic_model' },
        'object_2' => { 'type' => 'embedded_polymorphic_model' },
        'polyref_1' => { 'type' => 'polymorphic_reference' },
        'polyref_2' => { 'type' => 'polymorphic_reference' },
        'virtual' => { 'type' => 'string' }
      },
      'object_actions' => { 'read' => {}, 'write' => {}, 'delete' => {} },
      'class_actions' => { 'create' => {} },
      'class_perms' => { 'create' => true }
    })
  end

  it 'hides excluded attributes' do
    get 'schema', :format => :json
    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should deep_include({
      'type' => 'Company',
      'attrs' => {
        'id' => { 'type' => 'integer' },
        'created_at' => { 'type' => 'timestamp' },
      }
    })
  end

  it 'prevents updating non writable attributes' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :not_writable_attribute => 0,
         }.to_json

    put :update, :id => @c2.id, :format => :json

    response.status.should == 422
  end

  it 'responds to index' do
    get :index, :format => :json

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should deep_include([
      { 'id' => 1 },
      { 'id' => 2 },
      { 'id' => 3 },
    ])
  end

  it 'retrieves a record by its ID' do
    get :show, :id => @c2.id,  :format => :json
    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should deep_include({
      'id' => 2,
      'name' => 'compuglobal',
      'full_address' => {
        'city' => 'Springfield',
        'street' => 'Bart\'s road',
        'zip' => '513',
      },
    })
  end

  it 'retrieves a record by its ID in XML' do
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

  it 'sets ar_view to action name if not specified in the URI parameters' do
    get :show, :id => @c2.id, :format => :json

    controller.ar_view.should be_a(ActiveRest::View)
    controller.ar_view.name.should == :show
  end

  it 'sets ar_view to URI parameter view if specified' do
    get :show, :id => @c2.id, :format => :json, :view => 'foobar'

    controller.ar_view.should be_a(ActiveRest::View)
    controller.ar_view.name.should == :foobar
  end

  it 'creates a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :name => 'New Company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }.to_json

    post :create, :format => :json

    response.status.should == 201
  end

  it 'rejects unknown fields in data while creating a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :unknown_field => 'oh oh' }.to_json

    post :create, :format => :json

    response.status.should == 400
  end

  it 'rejects invalid data while creating a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :city => 'no where' }.to_json

    post :create, :format => :json

    response.status.should == 422
#    response.should match("<company[name]>can't be blank</company[name]>")
  end

  it 'respects validations checks while creating a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :name => @c2.name }.to_json

    post :create, :format => :json

    response.status.should == 422
#    response.should match(" <company[name]>has already been taken</company[name]>")
  end

  it 'updates records' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :name => 'New Compuglobal TM' }.to_json

    put :update, :id => @c2.id, :format => :json

    # Both are valid however Rails limits to 204
    [ 200, 204 ].should include(response.status)
  end

  it 'rejects updates to a record with unknown field in data' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :unknown_field => 'oh oh' }.to_json

    put :update, :id => @c2.id, :format => :json

    response.status.should == 400
  end

  it 'avoids updates to a record with invalid data' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
          :name => nil,
          :city => 'new location'
        }.to_json

    put :update, :id => @c2.id, :format => :json

    response.status.should == 422
#    response.should match("<company[name]>can't be blank</company[name]>")
  end

  it 'deletes a record' do
    id = @c2.id
    delete :destroy, :id => id, :format => :json
    response.should be_success

    get :show, :id => id, :format => :json

    response.should_not be_success
    response.status.should == 404
  end

  it 'rejects deletion of an unknown record' do

    delete :destroy, :id => 100, :format => :json

    response.should_not be_success
    response.status.should == 404
  end
end

#
# REST VALIDATIONS
#
describe CompaniesController do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
    @c2 = FactoryGirl.create(:company_2)
    @c3 = FactoryGirl.create(:company_3)
  end

  it 'validates resource creation without creating the object' do
    request.headers['X-Validate-Only'] = true
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :name => 'Brand new PRO company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }.to_json

    post :create, :format => :json

    response.status.should == 202

    # check the full list
    get :index,  :format => :json
#    response.should_not match('<name>Brand new PRO company</name>')
  end

  it 'validates resource update without creating the object' do
    request.headers['X-Validate-Only'] = true
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :name => 'Renamed to Compuglobal TM' }.to_json

    put :update, :id => @c2.id, :format => :json

    response.status.should == 202

    # try to read - the value must be the previous
    get :show, :id => @c2.id, :format => :json
#    response.should match('<name>' + @c2.name + '</name>')
  end
end
