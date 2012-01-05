class ExternalObjectFoo < ActiveRecord::Base
  include ActiveRest::Model

  interface :rest do
  end
end
