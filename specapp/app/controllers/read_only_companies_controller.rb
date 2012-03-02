
class ReadOnlyCompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  rest_controller_for Company
  read_only!
end
