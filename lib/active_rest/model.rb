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

class Hash
  def export_to_hash(opts = {})
    out = {}
    self.each do |k,v|
      out[k] = v.export_to_hash(options)
    end
    out
  end
end

class Array
  def export_to_hash(opts = {})
    self.map { |v| v.export_to_hash(options) }
  end
end

module ActiveRest
module Model

  class Attribute

    class DSL
      def initialize(klass)
        @klass = klass
      end

      def human_name(name)
        @klass.human_name = name
      end

      def meta(meta)
        @klass.meta ||= {}
        @klass.meta.merge!(meta)
      end
    end

    attr_accessor :name
    attr_accessor :type
    attr_accessor :source
    attr_accessor :human_name
    attr_accessor :meta
    attr_accessor :klass

    def initialize(klass, name, h = {})
      @klass = klass
      @name = name

      if h[:clone_from]
        @human_name = h[:clone_from].human_name
        @meta = h[:clone_from].meta
      end

      @type = h[:type]
      @source = h[:source]

      @human_name ||= h[:human_name]
      @meta ||= h[:meta]
    end

    def definition
      res = {
        :type => type,
      }

      res[:human_name] = @human_name if @human_name

      res
    end

    def value(object)
#      object.instance_eval(&@source) if @source

      # FIXME Workaround for ruby bug
      if @source.is_a?(Symbol)
        object.send(@name)
      elsif @source.is_a?(Proc)
        object.instance_eval(&@source)
      end
    end
  end

  class SimpleAttribute < Attribute
    attr_accessor :primary
    attr_accessor :null
    attr_accessor :default

    def initialize(klass, name, h = {})
      super klass, name, h

      @primary = h[:primary]
      @null = h[:null]
      @default = h[:default]
    end

    def definition
      res = super

      res[:primary] = @primary if @primary
      res[:null] = @null
      res[:default] = @default if @default

      res[:edit_on_creation] = true
      res[:visible_on_creation] = true

      res[:after_creation_perms] = {
        :write => true,
        :read => true,
      }

      res
    end

  end

  class StructuredAttribute < Attribute
    attr_accessor :model_class
    attr_accessor :embedded
    attr_accessor :member_attributes

    def initialize(klass, name, h = {})
      super klass, name, h

      @relation = true
      @embedded = h[:embedded]
      @model_class = h[:model_class]
    end

    def definition
      res = super

      res[:embedded] = @embedded if @embedded

      if @embedded
        res[:schema] = @model_class.constantize.schema
      else
        res[:schema] = {}
        res[:schema][:type] = @model_class
      end

      res
    end
  end

  class CollectionAttribute < StructuredAttribute
    def definition
      res = super

      if @embedded
        res[:members_schema] = @model_class.constantize.schema
      else
        res[:members_schema] = {}
        res[:members_schema][:type] = @model_class
      end

      res[:edit_on_creation] = true
      res[:visible_on_creation] = true

      res[:after_creation_perms] = {
        :write => true,
        :read => true,
      }

      res
    end
  end

  def self.included(base)
    base.class_eval do

    end

    base.extend(ClassMethods)
  end

  module ClassMethods

    def attribute(name, &block)
      @attrs ||= {}
      @attrs[name] ||= Attribute.new(self, name)
      Attribute::DSL.new(@attrs[name]).instance_eval(&block)
      @attrs[name]
    end

    def attrs
      initialize_attrs if !@attrs_initialized
      @attrs
    end

    def initialize_attrs
      @attrs ||= {}

      columns.each do |x|
        name = x.name.to_sym
        @attrs[name] =
          SimpleAttribute.new(self, name,
            :clone_from => @attrs[name],
            :source => x.name.to_sym,
            :type => map_column_type(x.type),
            :primary => x.primary,
            :null => x.null,
            :default => x.default,
            )
      end

      reflections.each do |name, reflection|

        case reflection.macro
        when :composed_of
          @attrs[name] =
            StructuredAttribute.new(self, name,
              :clone_from => @attrs[name],
              :source => nil,
              :type => reflection.macro,
              )
        when :belongs_to, :has_one

          @attrs[name] =
            StructuredAttribute.new(self, name,
              :clone_from => @attrs[name],
              :source => name.to_sym,
              :type => reflection.macro,
              :model_class => reflection.class_name,
              :embedded => !!(reflection.options[:embedded])
              )

        when :has_many
          @attrs[name] =
            CollectionAttribute.new(self, name,
              :clone_from => @attrs[name],
              :source => name.to_sym,
              :type => reflection.macro,
              :model_class => reflection.class_name,
              :embedded => !!(reflection.options[:embedded]),
              )
        else
          raise "Usupported reflection of type '#{reflection.macro}'"
        end
      end

      @attrs_initialized = true

      attrs
    end

    def schema(options = {})

      defs = {}

      attrs.each do |attrname,attr|
        defs[attrname] = attr.definition
      end

      if options[:additional_attrs]
        options[:additional_attrs].each do |attrname,attr|
          defs[attrname] ||= {}
          defs[attrname].deep_merge!(attr.definition)
        end
      end

      object_actions = {
        :read => {
        },
        :write => {
        },
        :delete => {
        }
        # TODO add specific action
      }

      class_actions = {
        :create => {}
      }

      class_perms = {
        :create => true
      }

      res = {
        :type => self.to_s,
        :type_symbolized => self.to_s.underscore.gsub(/\//, '_'),
        :attrs => defs,
        :object_actions => object_actions,
        :class_actions => class_actions,
        :class_perms => class_perms,
      }

      res
    end

    def map_column_type(type)
      case type
      when :datetime
        :timestamp
      else
        type
      end
    end
  end

  def export_as_hash(opts = {})
    values = {}
    perms = {}

    attrs.each do |attrname,attr|

      attrname = attrname.to_sym

      if attr.kind_of?(SimpleAttribute)
        values[attrname] = attr.value(self)
        values[attrname] = values[attrname].export_as_hash(opts) if values[attrname].respond_to?(:export_as_hash)
      elsif attr.kind_of?(CollectionAttribute)
        if attr.embedded
          recur_into_subattr(attrname, opts) do |newopts|
            values[attrname] = attr.value(self).map { |x| x.export_as_hash(newopts) }
          end
        end

      elsif attr.kind_of?(StructuredAttribute)
        if attr.embedded
          recur_into_subattr(attrname, opts) do |newopts|
            values[attrname] = attr.value(self) ? attr.value(self).export_as_hash(newopts) : nil
          end
        end

      else
        raise "Don't know how to handle attributes of type '#{attr.class}'"
      end

      perms[attrname] ||= {}
      perms[attrname][:read] = true
      perms[attrname][:write] = true
    end

    if opts[:additional_attrs]
      opts[:additional_attrs].each do |attrname,attr|
        if attr.source
          recur_into_subattr(attrname, opts) do |newopts|
            values[attrname] = attr.value(self)
            values[attrname] = values[attrname].export_as_hash(opts) if values[attrname].respond_to?(:export_as_hash)
          end

          perms[attrname] ||= {}
          perms[attrname][:read] = true
          perms[attrname][:write] = true
        end

        if attr.respond_to?(:do_include) && attr.do_include
          values[attrname] = self.send(attrname)
        end
      end
    end

    res = values

    res[:_type] = self.class.to_s
    res[:_type_symbolized] = self.class.to_s.underscore.gsub(/\//, '_').to_sym

    if opts[:with_perms]
      res[:_object_perms] = {
          :read => true,
          :write => true,
          :delete => true
        }

      res[:_attr_perms] = perms
    end

    res
  end

  def export_as_yaml(opts = {})
    export_as_hash.to_yaml(opts)
  end

  def as_json(opts = {})
    opts ||= {}
    export_as_hash({ :with_perms => true }.merge!(opts))
  end

  def attrs
    self.class.attrs
  end

  private

  def recur_into_subattr(attrname, options)
    newopts = {}
    if options[:additional_attrs] &&
       options[:additional_attrs][attrname] &&
       options[:additional_attrs][attrname].respond_to?(:sub_attributes)
      newopts = { :additional_attrs => options[:additional_attrs][attrname].sub_attributes }
    end

    yield newopts
  end

end

end
