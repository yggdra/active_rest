
class CompaniesReadOnlyController < ApplicationController
  include ActiveRest

  layout false
  rest_controller_for Company, :read_only => true
end
