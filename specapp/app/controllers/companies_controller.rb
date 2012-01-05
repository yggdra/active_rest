class CompaniesController < ApplicationController
  include ActiveRest::Controller

  rest_controller_for Company

  view :show do
  end

  view :foobar do
  end

  filter :my_custom_filter do
    false
  end

  layout false
end
