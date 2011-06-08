class AnotherOwnedObject < ActiveRecord::Base
  belongs_to :ownable, :polymorphic => true
end

