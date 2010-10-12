#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2010, Daniele Orlandi
#
# = ActiveRest::Controller::Core
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>,
#          Angelo Grossini <angelo@intercom.it>
#
# License:: Proprietary
#
# Revision:: $Id: core.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Model

  class Attribute
    attr_accessor :name
    attr_accessor :type
    attr_accessor :source
    attr_accessor :human_name

    def initialize(name, h = {})
      @name = name

      @type = h[:type]
      @source = h[:source]
      @human_name = h[:human_name]
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

    def initialize(name, h = {})
      super name, h

      @primary = h[:primary]
      @null = h[:null]
      @default = h[:default]
    end

    def definition
      res = super

      res[:primary] = @primary if @primary
      res[:null] = @null
      res[:default] = @default if @default

      res
    end

  end

  class CollectionAttribute < Attribute
    attr_accessor :model_class
    attr_accessor :embedded
    attr_accessor :member_attributes

    def initialize(name, h = {})
      super name, h

      @relation = true
      @embedded = h[:embedded]
      @model_class = h[:model_class]
    end

    def definition
      res = super

      res[:embedded] = @embedded if @embedded

      if @embedded
        res[:members_schema] = @model_class.constantize.schema
      else
        res[:members_schema] = {}
        res[:members_schema][:type] = @model_class
      end

      res
    end
  end

  def self.included(base)
    base.class_eval do

    end

    base.extend(ClassMethods)
  end

  module ClassMethods
    def attrs
      @attrs || @attrs = initialize_attrs
    end

    def initialize_attrs
      attrs = {}

      columns.each do |x|
        attrs[x.name] =
          SimpleAttribute.new(x.name,
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
          attrs[name] =
            CollectionAttribute.new(name,
              :source => nil,
              :type => reflection.macro,
              )
        else
          attrs[name] =
            CollectionAttribute.new(name,
              :source => name.to_sym,
              :type => reflection.macro,
              :model_class => reflection.class_name,
              :embedded => !!(reflection.options[:embedded]),
              )
        end
      end

      attrs
    end

    def recur_into_attr(key, options)

      newopts = options.clone

      if newopts[:ygg_additional_attrs] && newopts[:ygg_additional_attrs][key]
        newopts[:ygg_additional_attrs] = newopts[:ygg_additional_attrs][key].sub_attributes
      else
        newopts[:ygg_additional_attrs] = nil
      end

      yield newopts
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

  def as_json(options = {})
    values = {}
    perms = {}

    attrs.each do |attrname,attr|
      if attr.kind_of?(SimpleAttribute)
        values[attrname] = attr.value(self)
        perms[attrname] ||= {}
        perms[attrname][:read] = true
        perms[attrname][:write] = true
      elsif attr.kind_of?(CollectionAttribute) && attr.embedded

        add = {}
        if options[:additional_attrs] &&
           options[:additional_attrs][attrname] &&
           options[:additional_attrs][attrname].respond_to?(:sub_attributes)
          add = { :additional_attrs => options[:additional_attrs][attrname].sub_attributes }
        end

        values[attrname] = attr.value(self).map { |x| x.as_json(add) }
        perms[attrname] ||= {}
        perms[attrname][:read] = true
        perms[attrname][:write] = true
      end

    end

    if options[:additional_attrs]
      options[:additional_attrs].each do |attrname,attr|
        if attr.source
          values[attrname] = attr.value(self).as_json
          perms[attrname] ||= {}
          perms[attrname][:read] = true
          perms[attrname][:write] = true
        end
      end
    end

    object_perms = {
      :read => true,
      :write => true,
      :delete => true
    }

    res = {
      :_type => self.class.to_s,
      :_type_symbolized => self.class.to_s.underscore.gsub(/\//, '_'),
      :_object_perms => object_perms,
      :_attr_perms => perms,
    }.merge(values)

    res
  end

  def attrs
    self.class.attrs
  end

  private


end

end
