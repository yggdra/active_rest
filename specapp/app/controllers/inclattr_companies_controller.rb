class InclattrCompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  ar_controller_for Company

  view :show do
    attribute :group do
      include!
    end
  end

end
