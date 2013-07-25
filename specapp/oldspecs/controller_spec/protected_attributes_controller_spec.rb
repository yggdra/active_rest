#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class WithGuardProtectedAttributesController < ActionController::Base
  layout false
  ar_controller_for CompanyProtected, :index_options => { :finder => :basic }

  def guard_protected_attributes
    true # DO NOT let mass-assign - Rails' default
  end
end

class WithoutGuardProtectedAttributesController < ActionController::Base
  layout false
  ar_controller_for CompanyProtected, :index_options => { :finder => :basic }

  def guard_protected_attributes
    false # let mass-assign
  end
end



#
# 1^
#
describe WithGuardProtectedAttributesController do

  set_fixture_class :companies => CompanyProtected
  fixtures :companies

  before(:each) do
  end

  it 'should NOT be able to validate and create PROTECTED field of a new record' do
    params= {
      :name => 'New Company',
      :city => 'no where'
    }

    post :create, :format =>'xml', :company_protected => params, :_only_validation => :true
    response.body.should_not include_text(params[:city])
    response.status.should == STATUS[:s202]

    post :create, :format =>'xml', :company_protected => params
    response.status.should == STATUS[:s201]
    response.body.should_not include_text(params[:city])
  end

  it 'should NOT be able to validate and update PROTECTED fields for a record details' do
    params = {
      :name => 'New Compuglobal TM',
      :city => 'My new city'
    }

    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company_protected => params, :_only_validation => :true
    response.body.should_not include_text(params[:city])
    response.status.should == STATUS[:s202]

    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company_protected => params
    response.status.should == STATUS[:s202]
    response.body.should_not include_text(params[:city])
  end

end


#
# 2^
#
describe WithoutGuardProtectedAttributesController do

  set_fixture_class :companies => CompanyProtected
  fixtures :companies

  before(:each) do
  end

  it 'should be able to validate and create a new record' do
    params= {
      :name => 'New Company',
      :city => 'no where'
    }

    post :create, :format =>'xml', :company_protected => params, :_only_validation => :true
    response.status.should == STATUS[:s202]

    post :create, :format =>'xml', :company_protected => params
    response.status.should == STATUS[:s201]
    response.body.should include_text(params[:city])
  end

  it 'should be able to validate and update a record details' do
    params = {
      :name => 'New Compuglobal TM',
      :city => 'My new city'
    }

    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company_protected => params, :_only_validation => :true
    response.status.should == STATUS[:s202]

    put :update, :id => companies(:compuglobal).id, :format => 'xml', :company_protected => params
    response.status.should == STATUS[:s202]
    response.body.should include_text(params[:city])
  end

end
