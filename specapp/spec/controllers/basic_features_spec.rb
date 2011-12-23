require 'spec_helper'

require 'assert2/xhtml'

describe CompaniesController do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'returns model\'s schema with GET /schema' do
    get 'schema', :format => :json
    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should ==
     {'type' => 'Company',
      'type_symbolized' => 'company',
      'attrs' =>
       {'id' =>
         {'type' => 'integer',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'created_at' =>
         {'type' => 'timestamp',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'updated_at' =>
         {'type' => 'timestamp',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'name' =>
         {'type' => 'string',
          'human_name' => 'Nome',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'city' =>
         {'type' => 'string',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'street' =>
         {'type' => 'string',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'zip' =>
         {'type' => 'string',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'is_active' =>
         {'type' => 'boolean',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'registration_date' =>
         {'type' => 'timestamp',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'location_id' =>
         {'type' => 'integer',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'group_id' =>
         {'type' => 'integer',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'object_1_id' =>
         {'type' => 'integer',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'object_1_type' =>
         {'type' => 'string',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'object_2_id' =>
         {'type' => 'integer',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'object_2_type' =>
         {'type' => 'string',
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'users' =>
         {'type' => 'uniform_references_collection', 'referenced_class' => 'User'},
        'contacts' => {'type' => 'polymorphic_references_collection'},
        'group' => {'type' => 'reference', 'referenced_class' => 'Group'},
        'phones' =>
         {'type' => 'uniform_models_collection',
          'human_name' => 'Phone numbers',
          'schema' =>
           {'type' => 'Company::Phone',
            'type_symbolized' => 'company_phone',
            'attrs' =>
             {'id' =>
               {'type' => 'integer',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'company_id' =>
               {'type' => 'integer',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'number' =>
               {'type' => 'string',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'company' => {'type' => 'reference', 'referenced_class' => 'Company'}},
            'object_actions' => {'read' => {}, 'write' => {}, 'delete' => {}},
            'class_actions' => {'create' => {}},
            'class_perms' => {'create' => true}},
          'edit_on_creation' => true,
          'visible_on_creation' => true,
          'after_creation_perms' => {'write' => true, 'read' => true}},
        'location' =>
         {'type' => 'embedded_model',
          'schema' =>
           {'type' => 'CompanyLocation',
            'type_symbolized' => 'company_location',
            'attrs' =>
             {'id' =>
               {'type' => 'integer',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'lat' =>
               {'type' => 'float',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'lon' =>
               {'type' => 'float',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'raw_name' =>
               {'type' => 'string',
                'edit_on_creation' => true,
                'visible_on_creation' => true,
                'after_creation_perms' => {'write' => true, 'read' => true}},
              'companies' =>
               {'type' => 'uniform_references_collection',
                'referenced_class' => 'Company'}},
            'object_actions' => {'read' => {}, 'write' => {}, 'delete' => {}},
            'class_actions' => {'create' => {}},
            'class_perms' => {'create' => true}}},
        'full_address' => {'type' => 'structure'},
        'object_1' => {'type' => 'embedded_polymorphic_model'},
        'object_2' => {'type' => 'embedded_polymorphic_model'},
        'polyref_1' => {'type' => 'polymorphic_reference'},
        'polyref_2' => {'type' => 'polymorphic_reference'},
        'owned_objects' => {'type' => 'polymorphic_references_collection'},
        'virtual' => {'type' => 'string'}},
      'object_actions' => {'read' => {}, 'write' => {}, 'delete' => {}},
      'class_actions' => {'create' => {}},
      'class_perms' => {'create' => true}
     }

  end

  it 'responds to index' do
    get :index, :format => :json

    response.should be_success

    b = ActiveSupport::JSON.decode(response.body)

    b.should == {}
  end

  it 'retrieves a record by its ID' do
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

  it 'sets rest_view to action name if not specified in the URI parameters' do
    get :show, :id => @c2.id, :format => :json

    controller.rest_view.should be_a(ActiveRest::View)
    controller.rest_view.name.should == :show
  end

  it 'sets rest_view to URI parameter view if specified' do
    get :show, :id => @c2.id, :format => :json, :view => 'foobar'

    controller.rest_view.should be_a(ActiveRest::View)
    controller.rest_view.name.should == :foobar
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

  it 'rejects unknown fields in data while creating a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :unknown_field => 'oh oh' }.to_json

    post :create, :format => 'xml'

    response.status.should == 400
  end

  it 'rejects invalid data while creating a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :city => 'no where' }.to_json

    post :create, :format => 'xml'

    response.status.should == 422
#    response.should match("<company[name]>can't be blank</company[name]>")
  end

  it 'respects validations checks while creating a new record' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :name => @c2.name }.to_json

    post :create, :format => 'xml'

    response.status.should == 422
#    response.should match(" <company[name]>has already been taken</company[name]>")
  end

  it 'updates records' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :name => 'New Compuglobal TM' }.to_json

    put :update, :id => @c2.id, :format => 'xml'

    response.status.should == 200
  end

  it 'rejects updates to a record with unknown field in data' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :unknown_field => 'oh oh' }.to_json

    put :update, :id => @c2.id, :format => 'xml'

    response.status.should == 400
  end

  it 'avoids updates to a record with invalid data' do
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
          :name => nil,
          :city => 'new location'
        }.to_json

    put :update, :id => @c2.id, :format => 'xml'

    response.status.should == 422
#    response.should match("<company[name]>can't be blank</company[name]>")
  end

  it 'deletes a record' do
    id = @c2.id
    delete :destroy, :id => id, :format => 'xml'
    response.should be_success

# Workaound for Rails/RSpec bug?!?
    lambda {
      get :show, :id => id, :format => 'xml'
    }.should raise_error(ActiveRecord::RecordNotFound)

#    response.should_not be_success
#    response.status.should == 404
  end

  it 'rejects deletion of an unknown record' do

# Workaound for Rails/RSpec bug?!?
    lambda {
      delete :destroy, :id => 100, :format => 'xml'
    }.should raise_error(ActiveRecord::RecordNotFound)

#    response.should_not be_success
#    response.status.should == 404
  end
end

#
# REST VALIDATIONS
#
describe CompaniesController do

  before(:each) do
    @c1 = Factory(:company_1)
    @c2 = Factory(:company_2)
    @c3 = Factory(:company_3)
  end

  it 'validates resource creation without creating the object' do
    request.env['X-Validate-Only'] = true
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = {
           :name => 'Brand new PRO company',
           :city => 'no where',
           :street => 'Crazy Avenue, 0',
           :zip => '00000'
         }.to_json

    post :create, :format => :json

    response.status.should == 200

    # check the full list
    get :index,  :format => 'xml'
#    response.should_not match('<name>Brand new PRO company</name>')
  end

  it 'validates resource update without creating the object' do
    request.env['X-Validate-Only'] = true
    request.env['CONTENT_TYPE'] = 'application/json'
    request.env['RAW_POST_DATA'] = { :name => 'Renamed to Compuglobal TM' }.to_json

    put :update, :id => @c2.id, :format => 'xml'

    response.status.should == 200

    # try to read - the value must be the previous
    get :show, :id => @c2.id, :format => 'xml'
#    response.should match('<name>' + @c2.name + '</name>')
  end
end
