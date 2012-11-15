#
# ActiveRest
#
# Copyright (C) 2008-2011, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

require 'active_rest/model/interface'

# How interfaces work:
#
# When you define a new interface by default it is configured to automatically gather its attributes from the model
# columns and reflection. This, however, is an expensive operation because it requires accessing the database.
# Thus, the attributes specified in code are temporarily stored in attributed_defined_in_code to be subsequently applied to
# the autoconfigured ones.


module ActiveRest
module Model

  def self.included(base)
    base.extend(ClassMethods)
    base.class_attribute :interfaces
    base.interfaces = {}

    base.class_eval do
      class << self
        alias_method_chain :inherited, :ar
      end
    end
  end

  class ModelError < StandardError ; end
  class UnknownRelation < ModelError ; end
  class UnknownField < ModelError ; end
  class PolymorphicRelationNotSupported < ModelError ; end

  module ClassMethods

    def inherited_with_ar(child)
      inherited_without_ar(child)

      child.interfaces = child.interfaces.clone
      child.interfaces.each { |k,v| (child.interfaces[k] = v.clone).model = child }
    end

    def interface(name, &block)
      self.interfaces[name] ||= Interface.new(name, self)
      self.interfaces[name].instance_exec(&block)
    end

    def nested_attribute(attrs, path = [])
      attrs = attrs.to_s.split('.') if !attrs.kind_of?(Array)

      if attrs.count == 1
        attr = self.scoped.table[attrs[0]]

        raise UnknownField, "Unknown field '#{attrs[0]}' in model #{self.name}" if !attr || !self.columns_hash[attrs[0]]
        return attr, path
      end

      path.push(attrs[0].to_sym)

      reflection = reflections[attrs[0].to_sym]
      raise UnknownField, "Unknown relation #{attrs[0]}" if !reflection

      if reflection.options[:polymorphic]
        raise PolymorphicRelationNotSupported
      end

      reflection.klass.nested_attribute(attrs[1..-1], path)
    end
  end

  def output(interface_name, opts = {})
    opts[:view] ||= ActiveRest::View.new(:default)
    opts[:format] ||= :json
    interfaces[interface_name].output(self, opts)
  end

  def ar_serializable_hash(interface_name, opts = {})
    raise "Interface #{interface_name} is not defined for class #{self.class.name}" if !interfaces[interface_name]

    interfaces[interface_name].ar_serializable_hash(self, opts)
  end

end

end
