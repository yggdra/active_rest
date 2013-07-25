
class ReadOnlyCompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  ar_controller_for Company
  read_only!
end
