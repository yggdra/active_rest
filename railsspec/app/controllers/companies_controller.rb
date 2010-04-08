class CompaniesController < ApplicationController
  include ActiveRest

  layout false
  rest_controller_for Company
end
