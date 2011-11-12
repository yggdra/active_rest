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

module ActiveRest
module Model

  # Base class for attributes
  #
  class Attribute

    attr_accessor :binding

    attr_accessor :name
    attr_accessor :human_name
    attr_accessor :default
    attr_accessor :notnull
    attr_accessor :meta

    def initialize(binding, name, h = {})
      @binding = binding
      @name = name

      @human_name ||= h[:human_name]
      @meta = h[:meta] || {}
      @default = h[:default] || nil
      @notnull = h[:notnull] || false
    end

    def definition
      res = { :type => type }
      res[:human_name] = @human_name if @human_name
      res[:default] = @default if @default
      res[:notnull] = true if @notnull
      res[:meta] = @meta if !@meta.empty?
      res
    end

    def type
      self.class.name.split('::').last.underscore.to_sym
    end

    def apply(attr)
      @human_name = attr.human_name
      @meta.merge!(attr.meta)
    end

    class DSL
      def initialize(model, attrs, name)
        @model = model
        @attrs = attrs
        @name = name
      end

      def human_name(name)
        @attrs[@name].human_name = name
      end

      def meta(meta)
        @attrs[@name].meta ||= {}
        @attrs[@name].meta.merge!(meta)
      end

      def virtual(type, &block)
        @attrs[@name] = Attribute::Virtual.new(@model, @name, :clone => @attrs[@name], :type => type, :value => block)
      end
    end

    # Simple attribute describes an attribute containing a single flat value
    # Database columns are normally mapped to simple attributes
    #
    class Simple < Attribute
      attr_accessor :default
      attr_reader :type

      def initialize(klass, name, h = {})
        super klass, name, h

        @type = h[:type]
      end

      def definition
        res = super

        res[:edit_on_creation] = true
        res[:visible_on_creation] = true

        res[:after_creation_perms] = {
          :write => true,
          :read => true,
        }

        res
      end
    end

    #
    class Structure < Attribute
    end

    # Reference to another linked but not embedded model. It may come from a has_one or belongs_to
    #
    class Reference < Attribute
      def initialize(klass, name, h = {})
        super klass, name, h

        @referenced_class_name = h[:referenced_class_name]
      end

      def definition
        res = super
        res[:referenced_class] = @referenced_class_name
        res
      end
    end

    # EmbeddedModel describes an attribute containing an embedded model
    #
    class EmbeddedModel < Attribute
      def initialize(klass, name, h = {})
        super klass, name, h

        @model_class = h[:model_class]
      end

      def definition
        res = super
        res[:schema] = @model_class.constantize.schema
        res
      end
    end

    # UniformModelsCollection is a collection of objects of the same type
    #
    class UniformModelsCollection < Attribute
      def initialize(klass, name, h = {})
        super klass, name, h

        @model_class = h[:model_class]
      end

      def definition
        res = super

        res[:schema] = @model_class.constantize.schema

        res[:edit_on_creation] = true
        res[:visible_on_creation] = true

        res[:after_creation_perms] = {
          :write => true,
          :read => true,
        }

        res
      end
    end

    # UniformReferencesCollection is a collection of objects of the same type
    #
    class UniformReferencesCollection < Attribute
      def initialize(klass, name, h = {})
        super klass, name, h

        @referenced_class_name = h[:referenced_class_name]
      end

      def definition
        res = super
        res[:referenced_class] = @referenced_class_name
        res
      end
    end

    # EmbeddedPolymorphicModel
    #
    class EmbeddedPolymorphicModel < Attribute
    end

    # PolymorphicReference
    #
    class PolymorphicReference < Attribute
    end

    # PolymorphicModelsCollection
    #
    class PolymorphicModelsCollection < Attribute
    end

    # PolymorphicReferencesCollection
    #
    class PolymorphicReferencesCollection < Attribute
    end

    # Virtual
    #
    class Virtual < Attribute
      attr_reader :type

      def initialize(klass, name, h = {})
        super klass, name, h
        @type = h[:type]
        @value = h[:value]
      end

      def value(object)
        @value.is_a?(Proc) ? object.instance_eval(&@value) : @value
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)

    base.instance_eval do
      class_inheritable_accessor :attrs_defined_in_code
    end

    base.attrs_defined_in_code = {}
  end

  module ClassMethods

    def attribute(name, &block)
      a = @attrs || attrs_defined_in_code

      a[name] ||= Attribute.new(self, name)
      Attribute::DSL.new(self, a, name).instance_eval(&block)
      a[name]
    end

    def attrs
      @attrs || initialize_attrs
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

    def initialize_attrs
      @attrs = {}

      columns.each do |x|
        name = x.name.to_sym
        @attrs[name] =
          Attribute::Simple.new(self, name,
            :source => x.name.to_sym,
            :type => map_column_type(x.type),
            :default => x.default,
            :notnull => !x.null,
            )
      end

      reflections.each do |name, reflection|

        case reflection.macro
        when :composed_of
          @attrs[name] =
            Attribute::Structure.new(self, name,
              :type => reflection.macro,
             )

        when :belongs_to, :has_one
          if reflection.options[:polymorphic]
            if reflection.options[:embedded]
              @attrs[name] = Attribute::EmbeddedPolymorphicModel.new(self, name)
            else
              @attrs[name] = Attribute::PolymorphicReference.new(self, name)
            end
          else
            if reflection.options[:embedded]
              @attrs[name] =
                Attribute::EmbeddedModel.new(self, name,
                  :relation_type => reflection.macro,
                  :model_class => reflection.class_name
                 )
            else
              @attrs[name] =
                Attribute::Reference.new(self, name,
                  :type => reflection.macro,
                  :referenced_class_name => reflection.class_name,
                 )
            end
          end

        when :has_many
          if reflection.options[:as]
            if reflection.options[:embedded]
              @attrs[name] =
                Attribute::PolymorphicModelsCollection.new(self, name,
                  :type => reflection.macro,
                  :model_class => reflection.class_name,
                 )
            else
              @attrs[name] =
                Attribute::PolymorphicReferencesCollection.new(self, name,
                  :type => reflection.macro,
                  :referenced_class_name => reflection.class_name,
                 )
            end
          else
            if reflection.options[:embedded]
              @attrs[name] =
                Attribute::UniformModelsCollection.new(self, name,
                  :type => reflection.macro,
                  :model_class => reflection.class_name,
                 )
            else
              @attrs[name] =
                Attribute::UniformReferencesCollection.new(self, name,
                  :type => reflection.macro,
                  :referenced_class_name => reflection.class_name,
                 )
            end
          end

        else
          raise "Usupported reflection of type '#{reflection.macro}'"
        end
      end

      attrs_defined_in_code.each do |attrname, attr|
        if @attrs[attrname]
          @attrs[attrname].apply(attr)
        else
          @attrs[attrname] = attr
        end
      end

      @attrs
    end

    def schema(options = {})

      defs = {}

      attrs.each do |attrname,attr|
        defs[attrname] = attr.definition
      end

      object_actions = {
        :read => {
        },
        :write => {
        },
        :delete => {
        }
        # TODO add specific actions
      }

      class_actions = {
        :create => {}
      }

      class_perms = {
        :create => true
      }

      res = {
        :type => self.to_s,
        :type_symbolized => self.to_s.underscore.gsub(/\//, '_').to_sym,
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

  def attrs
    self.class.attrs
  end

  class UnknownField < StandardError; end


end

end
