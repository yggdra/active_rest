class Account < ActiveRecord::Base

  include ActiveRest::Model

  def self.authorizable?
    true
  end

  def capabilities_for(context)
    if name == 'Account3 Sfigato'
      return []
    end

    case context.auth_identity
    when 1 ; [ ]
    when 2 ; [ :edit_as_user ]
    when 3 ; [ :edit_as_reseller ]
    when 4 ; [ :edit_as_admin ]
    when 5 ; [ :edit_as_admin, :special_functions ]
    else ; []
    end
  end

  def self.capabilities_for(context)
    if context.auth_identity == 4
      [ :creator ]
    else
      [ ]
    end
  end

  def has_capability?(context, capa)
    capabilities_for(context).include?(capa)
  end

  interface :rest do
    action :create
    action :show
    action :update
    action :destroy
    action :special_action

    capability :creator do
      allow :create
    end

    capability :edit_as_user do
      allow :show
      readable :name
    end

    capability :edit_as_reseller do
      allow :show
      allow :update
      rw :name
      readable :balance
    end

    capability :edit_as_admin do
      allow :show
      allow :update
      allow :destroy
      default_readable!
      default_writable!
    end

    capability :special_functions do
      allow :special_action
    end

    capability :superuser do
      allow_all_actions!
      default_readable!
      default_writable!
    end
  end
end
