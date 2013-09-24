require 'spec_helper'

describe ActiveRest::Controller do

  it 'autoconfigures model if possible' do
    UsersController.ar_model.should == User
  end

  it 'fails silently if unable' do
    lambda {
      class FooBarBlahBlahsController < ApplicationController
        include ActiveRest::Controller
      end
    }.should_not raise_error

    FooBarBlahBlahsController.ar_model.should be_nil
  end

end

