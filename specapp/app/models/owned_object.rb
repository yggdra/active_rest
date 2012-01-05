class OwnedObject < ActiveRecord::Base
  include ActiveRest::Model

  belongs_to :ownable, :polymorphic => true

  interface :rest do
  end
end
