#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../models/company')
require File.expand_path(File.dirname(__FILE__) + '/../models/user')
require File.expand_path(File.dirname(__FILE__) + '/../models/contact')

#
# initialize each test + fixture loading
#
describe 'A simple setup', :shared => true do
  before( :each ) do
  end

  set_fixture_class :companies => Company
  fixtures :companies

  set_fixture_class :users => User
  fixtures :users

  set_fixture_class :contacts => Contact
  fixtures :contacts
end


#
################################### TESTS
#

# A
class ModelJoinsAController < ActionController::Base
  layout false
  rest_controller_for Company , :model_options => { :join => { :users => [:name] } }
end

describe ModelJoinsAController do
  it_should_behave_like 'A simple setup'

  it 'should be allow to join a single field on Model action' do
    get :index, :format => 'xml'
    #puts response.body
    response.should be_success
    response.should include_text('<users-name type="">')
  end
end

# B
class ModelJoinsBController < ActionController::Base
  layout false
  rest_controller_for Company , :model_options => { :join => { :users => { :name => 'new_name' } } }
end

describe ModelJoinsBController do
  it_should_behave_like 'A simple setup'

  it 'should be allow field name remapping' do
    get :index, :format => 'xml'
    #puts response.body
    response.should be_success
    response.should include_text('<new-name type="">')
  end
end

# C
class ModelJoinsCController < ActionController::Base
  layout false
  rest_controller_for Company , :model_options => { :join => { :users => true } }
end

describe ModelJoinsCController do
  it_should_behave_like 'A simple setup'

  it 'should be return all the joined fields on Model action' do
    get :index, :format => 'xml'
    response.should be_success
    response.should include_text('<users-company-id type="">')
    response.should include_text('<users-id type="">')
    response.should include_text('<users-name type="">')
  end
end

# D
class ModelJoinsDController < ActionController::Base
  layout false
  rest_controller_for Company , :model_options => { :join => { :users => false } }
end

describe ModelJoinsDController do
  it_should_behave_like 'A simple setup'

  it 'should be NOT return any joined fields on Model action' do
    get :index, :format => 'xml'
    response.should be_success
    response.should_not include_text('<users-company-id type="">')
    response.should_not include_text('<users-id type="">')
    response.should_not include_text('<users-name type="">')
  end
end

# E
class ModelJoinsEController < ActionController::Base
  layout false
  rest_controller_for Company , :model_options => { :join => { :users => [:name], :contacts => true } }
end

describe ModelJoinsEController do
  it_should_behave_like 'A simple setup'

  it 'should be return aspected joined fields with mixed declaration on Model action' do
    get :index, :format => 'xml'
    response.should be_success

    response.should_not include_text('<users-company-id type="">')
    response.should_not include_text('<users-id type="">')
    response.should include_text('<users-name type="">')
    response.should include_text('<contacts-field type="">')
    response.should include_text('<contacts-value type="">')
    response.should include_text('<contacts-id type="">')
    response.should include_text('<contacts-owner-id type="">')
    response.should include_text('<contacts-owner-type type="">')
  end
end

# F
class ModelJoinsFController < ActionController::Base
  layout false
  rest_controller_for Company , :model_options => { :join => { :unknown_reflection => true, :contacts => true } }
end

describe ModelJoinsFController do
  it_should_behave_like 'A simple setup'

  it 'should be not return only valid joins with mixed declaration on Model action' do
    get :index, :format => 'xml'
    response.should be_success

    response.should_not include_text('unknown_reflection') # no unknown join
    response.should_not include_text('users') # no users join
    response.should include_text('<contacts-field type="">')
    response.should include_text('<contacts-value type="">')
    response.should include_text('<contacts-id type="">')
    response.should include_text('<contacts-owner-id type="">')
    response.should include_text('<contacts-owner-type type="">')
  end
end
