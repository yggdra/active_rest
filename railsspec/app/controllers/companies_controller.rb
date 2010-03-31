class CompaniesController < ApplicationController
  layout false
  rest_controller_for Company, :index_options => { :finder => :basic }
end
