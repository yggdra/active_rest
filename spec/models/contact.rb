#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

class Contact < ActiveRecord::Base
  set_table_name 'active_rest_contacts'

  belongs_to :owner, :polymorphic => true
end
