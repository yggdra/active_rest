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

  module ClassMethods

    def inherited_with_ar(child)
      inherited_without_ar(child)

      child.interfaces = child.interfaces.clone
      child.interfaces.each { |k,v| (child.interfaces[k] = v.clone).model = child }
    end

    def interface(name, &block)
      self.interfaces[name] ||= Interface.new(name, self)
      Interface::DSL.new(self.interfaces[name]).instance_eval(&block)
    end

    def nested_attribute(attrname, rel = self.scoped, table = rel.table)

      attr_split = attrname.to_s.split('.')

      if attr_split.count == 1
        attr = table[attr_split[0]]
        raise UnknownField, "Unknown field '#{attrname}'" if !attr
        return attr, rel
      end

      reflection = (reflection ? reflection : rel).reflections[attr_split[0].to_sym]
      raise UnknownField, "Unknown relation #{attr_split[0]}" if !reflection

      rel = rel.joins(attr_split[0].to_sym)

      nested_attribute(attr_split[1..-1].join('.'), rel, reflection.klass.scoped.table)
    end
  end

  def export_as_hash(opts = {})
    if opts[:view]
      opts[:view].process(self, opts)
    else
      View.new(:default).process(self, opts)
    end
  end

  def export_as_yaml(opts = {})
    export_as_hash.to_yaml(opts)
  end

  def as_json(opts = {})
    opts ||= {}
    export_as_hash(opts)
  end

end

end
