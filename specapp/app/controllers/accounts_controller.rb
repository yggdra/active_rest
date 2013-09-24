class AccountsController < ApplicationController
  include ActiveRest::Controller

  ar_controller_for Account

  view :show do
  end

  view :foobar do
  end

  layout false

  def special_action
    ar_retrieve_resource
    ar_authorize_action
  end
end
