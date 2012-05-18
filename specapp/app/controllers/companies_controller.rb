class CompaniesController < ApplicationController
  include ActiveRest::Controller

  rest_controller_for Company

  view :show do
  end

  view :foobar do
  end

  filter :filter1
  filter :filter2 => :scope1
  filter :filter3 do |rel|
    rel.where(:id => params[:foobar])
  end

  layout false
end
