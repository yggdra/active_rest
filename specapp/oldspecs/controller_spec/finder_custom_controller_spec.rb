#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__)+ '/../models/company')
require File.expand_path(File.dirname(__FILE__)+ '/../models/user')
require File.expand_path(File.dirname(__FILE__)+ '/../models/contact')

module BigCorporation
  module Finder

    protected

    def self.build_conditions(target_model, params, options={})
      { :conditions => { :id => 1 } }
    end
  end
end

class FinderCustomController < ActionController::Base
  layout false
  rest_controller_for Company, :index_options => { :finder => BigCorporation::Finder }
end

#
# Custom Finder
#
describe FinderCustomController do

  set_fixture_class :companies => Company
  fixtures :companies

  before(:each) do
  end

  it 'should be allow index action' do
    get :index, :format => 'xml'

    response.should be_success

    response.should include_text('<name>' + companies(:big_corp).name + '</name>')
    response.should_not include_text('<name>' + companies(:newerOS).name + '</name>')
    response.should_not include_text('<name>' + companies(:compuglobal).name + '</name>')
  end

end
