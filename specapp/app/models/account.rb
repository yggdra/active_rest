class Account < ActiveRecord::Base

  include ActiveRest::Model

  def capabilities_for(context)
    case context.auth_identity
    when 1 ; [ ]
    when 2 ; [ :edit_as_user ]
    when 3 ; [ :edit_as_reseller ]
    end
  end

  def can?(context, capa)
    capabilities_for(context).include?(capa)
  end

  interface :rest do
    capability :edit_as_user do
      readable :name
    end

    capability :edit_as_reseller do
      rw :name
      readable :secret
    end
  end
end
