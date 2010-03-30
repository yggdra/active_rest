#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Models::Overrides
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>,
#          Angelo Grossini <angelo@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: float_sanitization.rb 5105 2009-08-05 12:30:05Z rottame $
#
# == Description
#
#
# this a common patch to convert , into . for float fields
#

module ActiveRest
  module Models
    module Overrides
      module FloatSanitization
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def define_write_method(attr_name)
            col = self.columns_hash[attr_name.to_s]
            if col.type == :float
              define_write_method_float(attr_name)
            else
              define_write_method_other(attr_name)
            end
          end

          def define_write_method_other(attr_name)
            evaluate_attribute_method attr_name, "def #{attr_name}=(new_value);write_attribute('#{attr_name}', new_value);end", "#{attr_name}="
          end

          def define_write_method_float(attr_name)
            evaluate_attribute_method attr_name, "def #{attr_name}=(new_value);write_attribute('#{attr_name}', new_value.to_s.gsub(',','.'));end", "#{attr_name}="
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRest::Models::Overrides::FloatSanitization)
