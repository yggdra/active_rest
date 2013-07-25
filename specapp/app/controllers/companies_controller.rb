class CompaniesController < ApplicationController
  include ActiveRest::Controller

  ar_controller_for Company

  view :show do
  end

  view :foobar do
  end

  scope :scope1
  scope :scope2 => :scope_for_id_2
  scope :scope3 do |rel|
    rel.where(:id => params[:foobar])
  end

  layout false
end
