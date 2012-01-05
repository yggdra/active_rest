class Group < ActiveRecord::Base
  include ActiveRest::Model

  has_many :companies

  interface :rest do
  end
end
