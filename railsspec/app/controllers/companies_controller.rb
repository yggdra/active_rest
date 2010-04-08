class CompaniesController < ApplicationController
  include ActiveRest

  layout false
  rest_controller_for Company, :index_options => { :finder => :basic }
end
