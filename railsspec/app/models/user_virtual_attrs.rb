#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

class UserVirtualAttrs < ActiveRecord::Base
  set_table_name 'active_rest_users'

  include ActiveRest::Model

  belongs_to :company
  has_many :contacts,:as => :owner

  validates_presence_of :name
  validates_uniqueness_of :name

  #
  # we tell active rest that this model can be receive query all the fields (as usual)
  # but in particular it behaves in two different for company_id and company_label
  #
  # if we post company_id, active rest, will search on this field;
  # if we post a parameter called company_label, active rest ONLY WITH 'basic' finder will
  # build a join and search on the active_rest_tables.name field
  #
  attr_annotate :company_id

  attr_order :company_label
  attr_groups :virtual_attributes => [:company_label]

  #
  # this function is automagically searched by active rest to create virtual column with
  # any sort of values... In common use the value wil be a label, but it can be a image path,
  # an icon, whatever we need.
  #
  def virtual_attributes_generator
    return {
      :company_label => company.nil? ? '' : company.name
    }
  end
end
