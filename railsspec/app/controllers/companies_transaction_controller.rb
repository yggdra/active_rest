class CompaniesTransactionController < ApplicationController
  include ActiveRest

  layout false
  rest_controller_for Company
  rest_transaction_handler :xact_handler

  def xact_handler
    target_model.transaction do
      yield
    end
  end
end
