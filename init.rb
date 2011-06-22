#
# Yggdra DSL
#
# Copyright (C) 2008-2011, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

require 'active_rest/routes'

require 'active_record'

module ActiveRecord::Associations::ClassMethods
  @@valid_keys_for_has_many_association << :embedded
  @@valid_keys_for_has_one_association << :embedded << :embedded_in
  @@valid_keys_for_belongs_to_association << :embedded << :embedded_in
end
