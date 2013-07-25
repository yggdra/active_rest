class TransactionCompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  ar_controller_for Company

  self.ar_transaction_handler = :xact_handler

  def xact_handler
    model.transaction do
      yield
    end
  end
end
