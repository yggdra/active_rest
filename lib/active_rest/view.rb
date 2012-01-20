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

  def initialize(name, interface = :rest, &block)
    @name = name
    @interface = interface

    @definition = {}
    @empty = false
    @with_type = true
    @with_perms = true
    @per_class = {}

    @extjs_polymorphic_workaround = false

    self.instance_eval(&block) if block_given?
  end

  def process(obj, opts = {})

    if @per_class[obj.class.to_s]
      if @extjs_polymorphic_workaround
        clname = obj.class.to_s.underscore.gsub(/\//, '_')

        return {
          clname.to_sym => @per_class[obj.class.to_s].process(obj, opts),
          (clname + '_id').to_sym => obj.id,
          (clname + '_type').to_sym => obj.class.to_s,
        }
      else
        return @per_class[obj.class.to_s].process(obj, opts)
      end
    end

    values = {}
    perms = {}

    obj.interfaces[@interface].attrs.select { |k,v| visible?(k) && !v.excluded }.each do |attrname,attr|
      attrname = attrname.to_sym
      viewdef = @definition[attrname]
      viewinc = viewdef ? viewdef.include : false

      case attr
      when Model::Interface::Attribute::Structure
        val = obj.send(attrname)
        values[attrname] = (val.respond_to?(:export_as_hash) ? val.export_as_hash(opts) : nil) ||
                           (val.respond_to?(:to_hash) ? val.to_hash : nil) ||
                           (val.respond_to?(:to_s) ? val.to_s : nil)
      when Model::Interface::Attribute::Reference
        if viewinc
          subview = viewdef.subview || View.new(:default)
          val = obj.send(attrname)
          values[attrname] = val ? subview.process(val, opts) : nil
        end
      when Model::Interface::Attribute::EmbeddedModel
        subview = viewdef && viewdef.subview || View.new(:default)
        val = obj.send(attrname)
        values[attrname] = val ? subview.process(val, opts) : nil
      when Model::Interface::Attribute::UniformModelsCollection
        subview = (viewdef && viewdef.subview) || View.new(:default)
        values[attrname] = obj.send(attrname).map { |x| subview.process(x, opts) }
      when Model::Interface::Attribute::UniformReferencesCollection
        if viewinc
          subview = viewdef.subview || View.new(:default)
          values[attrname] = obj.send(attrname).map { |x| subview.process(x, opts) }
        end
      when Model::Interface::Attribute::EmbeddedPolymorphicModel
        subview = (viewdef && viewdef.subview) || View.new(:default)
        val = obj.send(attrname)
        values[attrname] = val ? subview.process(val, opts) : nil
      when Model::Interface::Attribute::PolymorphicReference
        if viewinc
          subview = viewdef.subview || View.new(:default)
          val = obj.send(attrname)
          values[attrname] = val ? subview.process(val, opts) : nil
        else
          ref = obj.association(attrname).reflection
          values[attrname] = { :id => obj.send(ref.foreign_key), :_type => obj.send(ref.foreign_type) }
        end
      when Model::Interface::Attribute::PolymorphicModelsCollection
      when Model::Interface::Attribute::PolymorphicReferencesCollection
      else
        values[attrname] = obj.send(attrname)

        if !values[attrname].nil?
          case attr.type
          when :string
            values[attrname] = values[attrname].to_s if values[attrname].respond_to?(:to_s)
          when :integer
            values[attrname] = values[attrname].to_i if values[attrname].respond_to?(:to_i)
          when :array
            values[attrname] = values[attrname].to_a if values[attrname].respond_to?(:to_a)
          when :hash
            values[attrname] = values[attrname].to_h if values[attrname].respond_to?(:to_h)
          end

          values[attrname] = values[attrname].export_as_simple if values[attrname].respond_to?(:export_as_simple)
        end
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
    end

    res = values

    if @with_type
      res[:_type] = obj.class.to_s
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
    @with_type = true
  end

  def without_type!
    @with_type = false
  end

  def attribute(name, &block)
    @definition[name] ||= Attribute.new(name)
    @definition[name].instance_eval(&block)
    @definition[name]
  end

  def per_class(name, &block)
    @per_class[name] = View.new(@name)
    @per_class[name].instance_eval(&block) if block_given?
    @per_class[name]
  end

  def extjs_polymorphic_workaround!
    @extjs_polymorphic_workaround = true
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

    def extjs_polymorphic_workaround!
      @subview ||= View.new(@name)
      @subview.extjs_polymorphic_workaround!
      @subview
    end

    def per_class(name, &block)
      @subview ||= View.new(@name)
      @subview.per_class(name, &block)
      @subview
    end

    def virtual(type, &block)
      @display = :show
      @source = block
    end
  end
end

end
