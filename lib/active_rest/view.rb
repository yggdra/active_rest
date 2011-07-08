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

class View
  attr_accessor :name
  attr_accessor :definition

  attr_accessor :empty
  attr_accessor :with_type
  attr_accessor :with_perms

  def initialize(name, &block)
    @name = name
    @definition = {}
    @empty = false
    @with_type = true
    @with_perms = true

    self.instance_eval(&block) if block_given?
  end

  def process(obj, opts = {})
    values = {}
    perms = {}

    obj.attrs.each do |attrname,attr|
      next if !visible?(attrname)

      attrname = attrname.to_sym

      case attr
      when Model::Attribute::Simple
        values[attrname] = obj.send(attrname)
        if values[attrname].respond_to?(:export_as_single_string)
          values[attrname] = values[attrname].export_as_single_string
        end
      when Model::Attribute::Structure
        val = obj.send(attrname)
        values[attrname] = (val.respond_to?(:export_as_hash) ? val.export_as_hash(opts) : nil) ||
                           (val.respond_to?(:to_hash) ? val.to_hash : nil) ||
                           (val.respond_to?(:to_s) ? val.to_s : nil)
      when Model::Attribute::Reference
        if @definition[attrname] && @definition[attrname].include
          subview = (definition[attrname] && definition[attrname].subview) || View.new(:default)
          val = obj.send(attrname)
          values[attrname] = val ? subview.process(val, opts) : nil
        end
      when Model::Attribute::EmbeddedModel
        subview = (definition[attrname] && definition[attrname].subview) || View.new(:default)
        val = obj.send(attrname)
        values[attrname] = val ? subview.process(val, opts) : nil
      when Model::Attribute::UniformModelsCollection
        subview = (definition[attrname] && definition[attrname].subview) || View.new(:default)
        values[attrname] = obj.send(attrname).map { |x| subview.process(x, opts) }
      when Model::Attribute::UniformReferencesCollection
        if @definition[attrname] && @definition[attrname].include
          subview = (definition[attrname] && definition[attrname].subview) || View.new(:default)
          values[attrname] = obj.send(attrname).map { |x| subview.process(x, opts) }
        end
      when Model::Attribute::EmbeddedPolymorphicModel
        subview = (definition[attrname] && definition[attrname].subview) || View.new(:default)
        val = obj.send(attrname)
        values[attrname] = val ? subview.process(val, opts) : nil
      when Model::Attribute::PolymorphicReference
      when Model::Attribute::PolymorphicModelsCollection
      when Model::Attribute::PolymorphicReferencesCollection
      when Model::Attribute::Virtual
        values[attrname] = attr.value(obj)
      else
        raise "Don't know how to handle attributes of type '#{attr.class}'"
      end

      if @with_perms
        perms[attrname] ||= {}
        perms[attrname][:read] = true
        perms[attrname][:write] = true
      end
    end

    @definition.each do |attrname,attr|
      if attr.source
        values[attrname] = obj.instance_eval(&attr.source)
      end

#        if attr.source
#          recur_into_subattr(attrname, opts) do |newopts|
#            values[attrname] = attr.value(self)
#            values[attrname] = values[attrname].export_as_hash(opts) if values[attrname].respond_to?(:export_as_hash)
#          end
#
#          perms[attrname] ||= {}
#          perms[attrname][:read] = true
#          perms[attrname][:write] = true
#        end
#
#        if attr.respond_to?(:do_include) && attr.do_include
#          values[attrname] = self.send(attrname)
#        end
#      end
    end

    res = values

    if @with_type
      res[:_type] = obj.class.to_s
      res[:_type_symbolized] = obj.class.to_s.underscore.gsub(/\//, '_').to_sym
    end

    if @with_perms
      res[:_object_perms] = {
          :read => true,
          :write => true,
          :delete => true
        }

      res[:_attr_perms] = perms
    end

    res
  end

  def visible?(attr)
    if @empty
      @definition[attr].display == :show
    else
      @definition[attr].nil? || @definition[attr].display != :hide
    end
  end

  # DSL
  def empty!
    @empty = true
    @with_type = false
    @with_perms = false
  end

  def with_perms!
    @with_perms = true
  end

  def without_perms!
    @with_perms = false
  end

  def with_type!
    @with_perms = true
  end

  def without_type!
    @with_perms = false
  end

  def attribute(name, &block)
    @definition[name] ||= Attribute.new(name)
    @definition[name].instance_eval(&block)
    @definition[name]
  end

  class Attribute
    attr_accessor :name
    attr_accessor :display
    attr_accessor :include
    attr_accessor :source

    attr_accessor :subview

    def initialize(name)
      @name = name
      @display = :default
    end

    def include!
      @include = :true
      @display = :show
    end

    def show!
      @display = :show
    end

    def hide!
      @display = :hide
    end

    def attribute(name, &block)
      @subview ||= View.new(@name)
      @subview.attribute(name, &block)
      @subview
    end

    def empty!
      @subview ||= View.new(@name)
      @subview.empty!
      @subview
    end

    def virtual(type, &block)
      @display = :show
      @source = block
    end
  end


#
#    def definition
#      res = super
#
#      if !sub_attributes.empty?
#        res[:members_schema] ||= {}
#        sub_attributes.each do |k,v|
#          res[:members_schema][:attrs] ||= {}
#          res[:members_schema][:attrs][k] = v.definition
#        end
#      end
#
#      res
#    end

end

end
