class CompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  rest_controller_for Company
end
