class Contact < ActiveRecord::Base
  include ActiveRest::Model

  belongs_to :owner, :polymorphic => true
end
