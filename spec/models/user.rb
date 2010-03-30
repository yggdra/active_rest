#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

class User < ActiveRecord::Base
  set_table_name 'active_rest_users'

  belongs_to :company
  has_many :contacts,:as => :owner
end
