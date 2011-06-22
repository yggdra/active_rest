
require 'active_rest/railtie'
require 'active_rest/routes'
require 'active_rest/model'
require 'active_rest/view'
require 'active_rest/controller'

require 'active_record'

module ActiveRecord::Associations::ClassMethods
  @@valid_keys_for_has_many_association << :embedded
  @@valid_keys_for_has_one_association << :embedded << :embedded_in
  @@valid_keys_for_belongs_to_association << :embedded << :embedded_in
end

