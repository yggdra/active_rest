class Contact < ActiveRecord::Base
  include ActiveRest::Model

  belongs_to :owner, :polymorphic => true

  interface :rest do
  end
end
