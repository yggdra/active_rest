class CompaniesController < ApplicationController
  include ActiveRest::Controller

  view :show do
  end

  view :foobar do
  end

  layout false
  rest_controller_for Company
end
