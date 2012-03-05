class TransactionCompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  rest_controller_for Company

  self.rest_transaction_handler = :xact_handler

  def xact_handler
    model.transaction do
      yield
    end
  end
end
