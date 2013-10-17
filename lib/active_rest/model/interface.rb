#
# ActiveRest
#
# Copyright (C) 2008-2013, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

require 'active_rest/model/interface/attribute'
require 'active_rest/model/interface/capability'

class Array
  def ar_serializable_hash(ifname, opts = {})
    map do |x|
      x.respond_to?(:ar_serializable_hash) ? x.ar_serializable_hash(ifname, opts) : x
    end
  end
end

class Hash
  def ar_serializable_hash(ifname, opts = {})
    nh = self.clone
    each { |k,v| nh[k] = v.respond_to?(:ar_serializable_hash) ? v.ar_serializable_hash(ifname, opts) : v }
  end
end

module ActiveRest
module Model

class Interface
  attr_accessor :name
  attr_reader :model
  attr_accessor :allow_polymorphic_creation
  attr_reader :views
  attr_accessor :activerecord_autoinit

  attr_reader :config_attrs

  attr_reader :capabilities

  def initialize(name, model, opts = {})
    @name = name
    @opts = opts
    @config_attrs = {}
    @views = {}
    @activerecord_autoinit = true
    @attrs = nil
    @capabilities = {}

    @allow_polymorphic_creation = false

    self.model = model
  end

  def model=(model)
    @model = model

    @activerecord_autoinit = false if !(model <= ActiveRecord::Base)
  end

  def initialize_copy(source)
    @views = @views.clone
    @views.each { |k,v| @views[k] = v.clone }

    if @attrs
      @attrs = @attrs.clone
      @attrs.each { |k,v| (@attrs[k] = v.clone).interface = self }
    end

    if @config_attrs
      @config_attrs = @config_attrs.clone
      @config_attrs.each { |k,v| (@config_attrs[k] = v.clone).interface = self }
    end

    if @capabilities
      @capabilities = @capabilities.clone
    end

    super
  end

  def attrs
    @attrs || initialize_attrs
  end

  def initialize_attrs
    if @activerecord_autoinit
      autoinitialize_attrs_from_ar_model
    else
      @attrs = @config_attrs
      @config_attrs = nil
    end

    @attrs
  end

  def mark_attr_to_be_excluded(name)
    if @attrs[name]
      @attrs[name].exclude!
    else
      @config_attrs[name] ||= Attribute.new(name, @interface)
      @config_attrs[name].exclude!
    end
  end

  def autoinitialize_attrs_from_ar_model
    @attrs = {}

    @model.columns.each do |column|
      name = column.name.to_sym

      type = map_column_type(column.type)
      type = :object if @model.serialized_attributes[column.name]

      @attrs[name] =
        Attribute.new(name, self,
          :type => type,
          :default => column.default,
          :notnull => !column.null,
          :writable => ![ :id, :created_at, :updated_at ].include?(name),
        )
    end

    @model.reflections.each do |name, reflection|
      case reflection.macro
      when :composed_of
        @attrs[name] =
          Attribute::Structure.new(name, self, :type => reflection.macro, :model_class => reflection.options[:class_name])

        # Hide attributes composing the structure
        reflection.options[:mapping].each { |x| mark_attr_to_be_excluded(x[0].to_sym) }

      when :belongs_to
        if reflection.options[:polymorphic]
          if reflection.options[:embedded]
            @attrs[name] = Attribute::EmbeddedPolymorphicModel.new(name, self)

            mark_attr_to_be_excluded(reflection.foreign_key.to_sym)
            mark_attr_to_be_excluded(reflection.foreign_type.to_sym)
          else
            @attrs[name] = Attribute::PolymorphicReference.new(name, self)
          end
        else
          if reflection.options[:embedded]
            @attrs[name] =
              Attribute::EmbeddedModel.new(name, self,
                :model_class => reflection.class_name,
                :can_be_eager_loaded => true)

            # Hide embedded foreign key column
            mark_attr_to_be_excluded(reflection.foreign_key.to_sym)
          elsif reflection.options[:embedded_in]
            mark_attr_to_be_excluded(reflection.foreign_key.to_sym)
          else
            @attrs[name] =
              Attribute::Reference.new(name, self,
                :referenced_class_name => reflection.class_name,
                :foreign_key => reflection.foreign_key.to_s,
                :can_be_eager_loaded => true)
          end
        end

      when :has_one
        if reflection.options[:polymorphic]
          if reflection.options[:embedded]
            @attrs[name] = Attribute::EmbeddedPolymorphicModel.new(name, self)

            mark_attr_to_be_excluded(reflection.foreign_key.to_sym)
            mark_attr_to_be_excluded(reflection.foreign_type.to_sym)
          else
            @attrs[name] = Attribute::PolymorphicReference.new(name, self)
          end
        else
          if reflection.options[:embedded]
            @attrs[name] =
              Attribute::EmbeddedModel.new(name, self,
                :model_class => reflection.class_name,
                :can_be_eager_loaded => true)

            # Hide embedded foreign key column
            mark_attr_to_be_excluded(reflection.foreign_key.to_sym)
          else
            @attrs[name] =
              Attribute::Reference.new(name, self,
                :referenced_class_name => reflection.class_name,
                :can_be_eager_loaded => true)
          end
        end

      when :has_many
        if reflection.options[:embedded]
          @attrs[name] =
            Attribute::UniformModelsCollection.new(name, self,
              :model_class => reflection.class_name,
              :can_be_eager_loaded => true)
        else
          @attrs[name] =
            Attribute::UniformReferencesCollection.new(name, self,
              :referenced_class_name => reflection.class_name,
              :foreign_key => (!reflection.is_a?(ActiveRecord::Reflection::ThroughReflection) ? reflection.foreign_key : nil),
              :foreign_type => (!reflection.is_a?(ActiveRecord::Reflection::ThroughReflection) ? reflection.type : nil),
              :as => reflection.options[:as],
              :can_be_eager_loaded => true)
        end

      else
        raise "Usupported reflection of type '#{reflection.macro}'"
      end
    end

    @config_attrs.each do |attrname, attr|
      if @attrs[attrname]
        @attrs[attrname].apply(attr)
      else
        @attrs[attrname] = attr
      end
    end

    @attrs
  end

  def attribute(name, type = nil, &block)
    a = @attrs || @config_attrs

    name_in_model = name
    if name.is_a?(Hash)
      name_in_model, name = name.keys.first, name.values.first
    end

    if type
      begin
        a[name] ||= "ActiveRest::Model::Interface::Attribute::#{type}".constantize.new(name, self)
      rescue NameError
        a[name] ||= Attribute.new(name, self,
          :type => type.split('::').last.underscore.to_sym,
          :name_in_model => name_in_model)
      end
    else
      a[name] ||= Attribute.new(name, self, :name_in_model => name_in_model)
    end

    a[name].instance_exec(&block) if block
  end

  def capability(name, &block)
    capabilities[name] = Capability.new(name, self)
    capabilities[name].instance_exec(&block) if block
  end

  def view(name, &block)
    @views[name] ||= View.new(name)
    @views[name].instance_exec(&block) if block
    @views[name]
  end

  def schema(options = {})

    defs = {}

    attrs.select { |k,v| v.readable || v.writable }.each do |attrname,attr|
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
      :type => @model.to_s,
      :attrs => defs,
      :object_actions => object_actions,
      :class_actions => class_actions,
      :class_perms => class_perms,
    }

    res
  end

  def output(object, opts = {})
    opts[:format] ||= :json

    case opts[:format]
    when :json
      ActiveSupport::JSON.encode(ar_serializable_hash(object, opts))
    when :yaml
      YAML.dump(ar_serializable_hash(object, opts))
#    when :xml
#      (view.process(object, opts))
    else
      raise "Unsupported format #{format}"
    end
  end

  class ViewNotFound < StandardError ; end

  def eager_loading_hints(opts = {})

    view = opts[:view]

    if view.is_a?(Symbol)
      view = @views[view]
      raise ViewNotFound, "View #{opts[:view]} not found" if !view
    end

    view ||= View.new(:anonymous)

    incs = []
    attrs.each do |attrname,attr|
      next if view.attr_visible?(attrname) && attr.readable

      attrname = attrname.to_sym
      viewdef = view.definition[attrname]
      viewinc = viewdef ? viewdef.include : false
      subview = viewdef ? viewdef.subview : nil

      case attr
      when Model::Interface::Attribute::Reference
        incs << attrname if viewinc && attr.can_be_eager_loaded
      when Model::Interface::Attribute::EmbeddedModel
        incs << attrname if attr.can_be_eager_loaded
      when Model::Interface::Attribute::UniformModelsCollection
        # eager loading with limit is not supported:
        # http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html
        #

        if !viewdef || !viewdef.limit && attr.can_be_eager_loaded
          subinc = attr.model_class.constantize.interfaces[@name].eager_loading_hints(:view => subview)
          incs << (subinc.any? ? { attr.name_in_model => subinc } : attr.name_in_model)
        end
      when Model::Interface::Attribute::UniformReferencesCollection
        if viewinc && !viewdef.limit && attr.can_be_eager_loaded
          subinc = attr.referenced_class_name.constantize.interfaces[@name].eager_loading_hints(:view => subview)
          incs << (subinc.any? ? { attr.name_in_model => subinc } : attr.name_in_model)
        end
      when Model::Interface::Attribute::EmbeddedPolymorphicModel
      when Model::Interface::Attribute::PolymorphicReference
      when Model::Interface::Attribute::PolymorphicModelsCollection
      when Model::Interface::Attribute::PolymorphicReferencesCollection
      else
      end
    end

    incs += view.eager_loading_hints

    incs
  end

  def authorization_required?
    capabilities.any?
  end

  def relevant_capabilities(capas)
    capas &= capabilities.keys
  end

  def init_capabilities(aaa_context, resource = nil)
    # Build a list of capabilities the user *has*
    user_capas = []

    # First global capabilities
    user_capas += aaa_context.global_capabilities if aaa_context

    # Then capabilities given to the specific model by ACL
    user_capas += model.capabilities_for(aaa_context) if model.respond_to?(:capabilities_for)

    # Then capabilities given to the specific resource by the ACL
    user_capas += resource.capabilities_for(aaa_context) if resource && resource.respond_to?(:capabilities_for)

    # Filter out the capabilites not relevant to this resource
    user_capas = relevant_capabilities(user_capas)

    user_capas
  end

  def action_allowed?(capas, action)
    capas.any? { |x| capabilities[x.to_sym] ? capabilities[x.to_sym].allow_action?(action) : false }
  end

  def ar_serializable_hash(obj, opts = {})
    user_capas = nil

    if authorization_required?
      user_capas = init_capabilities(opts[:aaa_context], obj)
      raise ResourceNotReadable.new(obj) if user_capas.empty?
    end

    view = opts[:view]

    if view.is_a?(Symbol)
      view = @views[view]
      raise ViewNotFound, "View #{opts[:view]} not found" if !view
    end

    view ||= @views[:_default_] || View.new(:anonymous)

    with_perms = (view.with_perms || opts[:with_perms] == true) && opts[:with_perms] != false

    if view.per_class[obj.class.to_s]
      if view.extjs_polymorphic_workaround
        clname = obj.class.to_s.underscore.gsub(/\//, '_')

        return {
          clname.to_sym => ar_serializable_hash(obj, opts.merge(:view => view.per_class[obj.class.to_s])),
          (clname + '_id').to_sym => obj.id,
          (clname + '_type').to_sym => obj.class.to_s,
        }
      else
        return ar_serializable_hash(obj, opts.merge(:view => view.per_class[obj.class.to_s]))
      end
    end

    values = {}
    perms = {}
    attrs.each do |attrname,attr|
      attrname = attrname.to_sym

      readable =
         attr.readable && # Defined readable in interface
         attr_readable?(user_capas, attrname)

      writable =
         attr.writable && # Defined writable in interface
         attr_writable?(user_capas, attrname)

      if with_perms
        perms[attrname] ||= {}
        perms[attrname][:read] = readable
        perms[attrname][:write] = true
      end

      # Visible in view
      next if !view.attr_visible?(attrname)
      next if !readable

      viewdef = view.definition[attrname]
      viewinc = viewdef ? viewdef.include : false
      subview = viewdef ? viewdef.subview : nil

      case attr
      when Model::Interface::Attribute::Structure
        val = obj.send(attr.name_in_model)
        values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
      when Model::Interface::Attribute::Reference
        if viewinc
          val = obj.send(attr.name_in_model)
          values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
        end
      when Model::Interface::Attribute::EmbeddedModel
        val = obj.send(attr.name_in_model)
        values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
      when Model::Interface::Attribute::UniformModelsCollection
        vals = obj.send(attr.name_in_model)
        if viewdef
          vals = vals.limit(viewdef.limit) if viewdef.limit
          vals = vals.order(viewdef.order) if viewdef.order
        end
        values[attrname] = vals.map { |x| x.ar_serializable_hash(@name, opts.merge(:view => subview)) }
      when Model::Interface::Attribute::UniformReferencesCollection
        if viewinc
          vals = obj.send(attr.name_in_model)
          if viewdef
            vals = vals.limit(viewdef.limit) if viewdef.limit
            vals = vals.order(viewdef.order) if viewdef.order
          end
          values[attrname] = vals.map { |x| x.ar_serializable_hash(@name, opts.merge(:view => subview)) }
        end
      when Model::Interface::Attribute::EmbeddedPolymorphicModel
        val = obj.send(attr.name_in_model)
        values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
      when Model::Interface::Attribute::PolymorphicReference
        if viewinc
          val = obj.send(attr.name_in_model)
          values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
        else
          ref = obj.association(attr.name_in_model).reflection
          values[attrname] = { :id => obj.send(ref.foreign_key), :_type => obj.send(ref.foreign_type) }
        end
      when Model::Interface::Attribute::PolymorphicModelsCollection
      when Model::Interface::Attribute::PolymorphicReferencesCollection
      else
        val = obj.send(attr.name_in_model)

        if !val.nil?
          case attr.type
          when :string
            val = val.to_s if val.respond_to?(:to_s)
          when :integer
            val = val.to_i if val.respond_to?(:to_i)
          when :array
            val = val.to_a if val.respond_to?(:to_a)
          when :hash
            val = val.to_h if val.respond_to?(:to_h)
          end

#          val = val.to_ar if val.respond_to?(:to_ar)
        end

        values[attrname] = val
      end
    end

    view.definition.each do |attrname,attr|
      if attr.virtual_src
        values[attrname] = obj.instance_exec(&attr.virtual_src)
        values[attrname] = values[attrname].ar_serializable_hash(self.name) if values[attrname].respond_to? :ar_serializable_hash
      end
    end

    res = values

    if view.with_type
      res[:_type] = obj.class.to_s
    end

    if with_perms
      res[:_object_perms] = {
        :delete => true
      }

      res[:_attr_perms] = perms
    end

    res
  end

  def apply_creation_attributes(*args)
    apply_model_attributes(*args)
  end

  def apply_update_attributes(*args)
    apply_model_attributes(*args)
  end

  def apply_model_attributes(obj, values, opts = {})
    user_capas = nil

    if authorization_required?
      user_capas = init_capabilities(opts[:aaa_context], obj)
      raise ResourceNotWritable.new(obj) if user_capas.empty?
    end

    values.each do |attr_name, value|

      attr_name = attr_name.to_sym
      attr = attrs[attr_name]

      if attr_name == :_type
        next if !value
        next if @allow_polymorphic_creation && value.constantize <= obj.class
        next if value.constantize == obj.class

        raise ClassDoesNotMatch.new(obj.class, value.constantize)
      end
      next if attr_name == :id

      raise AttributeNotFound.new(obj, attr_name) if !attr
      next if attr.ignored

      writable =
         attr.writable &&
         attr_writable?(user_capas, attr_name)

      raise AttributeNotWritable.new(obj, attr_name) if !writable

      case attr
      when Attribute::Reference, Attribute::PolymorphicReference
        value = value.with_indifferent_access if value
        association = obj.association(attr_name)

        if association.loaded?
          record = association.target
        else
          record = association.reload.target
        end

        if value && attr.is_a?(Attribute::PolymorphicReference)
          association.target = value[:_type].constantize.find(value[:id])
        elsif value
          association.target = association.klass.find(value[:id])
        else
          association.target = nil
        end

      when Attribute::EmbeddedModel, Attribute::EmbeddedPolymorphicModel
        value = value.with_indifferent_access if value
        association = obj.association(attr_name)

        if association.loaded?
          record = association.target
        else
          record = association.reload.target
        end

        if !value || value[:_destroy]
          # DESTROY
          record.mark_for_destruction if record
        elsif record
          # UPDATE
          record.ar_apply_update_attributes(@name, value, opts)
        else
          # CREATE

          # We have to do this since it is embedded
          record.mark_for_destruction if record

          newrecord = nil
          if attr.is_a?(Attribute::EmbeddedPolymorphicModel)
            raise TypeMissing if !value[:_type]
            # XXX TODO Fail gracefully if type is not found
            newrecord = value[:_type].constantize.ar_new(@name, value, opts)
          else
            newrecord = association.klass.ar_new(@name, value, opts)
          end

          association.target = newrecord
        end

      when Attribute::UniformModelsCollection
        association = obj.association(attr_name)

        if association.loaded?
          existing_records = association.target
        else
          ids = value.map {|a| a['id'] || a[:id] }.compact
          existing_records = ids.empty? ? [] : association.scope.where(association.klass.primary_key => ids)
        end

        value.each do |val|
          val = val.with_indifferent_access

          # XXX Evaluate if id==9 is to be considered an indication to create record
          if !val.has_key?(:id) || val[:id].blank? || val[:id] == 0
            # CREATE
            if attr.model_class.constantize.interfaces[@name].allow_polymorphic_creation
              raise TypeMising if !val[:_type]
              # XXX TODO Fail gracefully if type is not found
              newrecord = val[:_type].constantize.ar_new(@name, val, opts)
            else
              raise ClassDoesNotMatch.new(obj.class, association.klass) if val[:_type] && val[:_type] != association.klass.name
              newrecord = association.klass.ar_new(@name, val, opts)
            end

            association.concat(newrecord)
          else
            existing_record = existing_records.detect { |x| x.id == val[:id] }
            raise AssociatedRecordNotFound.new if !existing_record

            if val[:_destroy]
              # DESTROY
              existing_record.mark_for_destruction
            else
              # UPDATE
              existing_record.ar_apply_update_attributes(@name, val, opts)
            end
          end
        end

      when Attribute::UniformReferencesCollection
        association = obj.association(attr_name)

        if association.loaded?
          existing_records = association.target
        else
          ids = value.map {|a| a['id'] || a[:id] }.compact
          existing_records = ids.empty? ? [] : association.scope.where(association.klass.primary_key => ids)
        end

        value.each do |val|
          val = val.with_indifferent_access

          existing_record = existing_records.detect { |x| x.id == val[:id] }

          if val[:_destroy]
            raise AssociatedRecordNotFound.new if !existing_record
            existing_record.destroy
          elsif !existing_record
            association.concat(association.klass.find(val[:id]))
          end
        end

      when Attribute::PolymorphicModelsCollection
        # Not supported because ActiveRecord has no concept of polymorphoc has_many
      when Attribute::PolymorphicReferencesCollection
        # Not supported because ActiveRecord has no concept of polymorphoc has_many

      when Attribute::Structure, Attribute
        obj.send("#{attr_name}=", value)
      end

    end
  end

  def map_column_type(type)
    case type
    when :datetime
      :timestamp
    when :text
      :string
    else
      type
    end
  end

  def to_s
    "<#{self.class.name} model=#{@model.class.name} name=#{@name} ai=#{@activerecord_autoinit}>"
  end

  def attr_readable?(capas, name)
    !authorization_required? || !!capas.map { |x| @capabilities[x.to_sym].readable?(name) }.reduce(&:|)
  end

  def attr_writable?(capas, name)
    !authorization_required? || !!capas.map { |x| @capabilities[x.to_sym].writable?(name) }.reduce(&:|)
  end

  class Error < StandardError
  end

  class AssociatedRecordNotFound < Error
  end

  class AttributeError < Error
    attr_accessor :object
    attr_accessor :attribute_name

    def initialize(object, attribute_name)
      @object = object
      @attribute_name = attribute_name
    end
  end

  class AttributeNotReadable < AttributeError
    def to_s
      "Attribute #{@attribute_name} in class #{@object.class} is not readable"
    end
  end

  class AttributeNotWritable < AttributeError
    def to_s
      "Attribute #{@attribute_name} in class #{@object.class} is not writable"
    end
  end

  class AttributeNotFound < AttributeError
    def to_s
      "Attribute #{@attribute_name} in class #{@object.class} not found"
    end
  end

  class ResourceNotReadable < Error
    attr_accessor :object

    def initialize(object)
      @object = object
    end

    def to_s
      "Resource #{@object.class.name} not readable"
    end
  end

  class ResourceNotWritable < Error
    attr_accessor :object

    def initialize(object)
      @object = object
    end

    def to_s
      "Resource #{@object.class.name} not writable"
    end
  end

  class ClassDoesNotMatch < Error
    attr_accessor :model_class
    attr_accessor :type

    def initialize(model_class, type)
      super

      @model_class = model_class
      @model_type = type
    end

    def to_s
      "Type #{@model_type} does not match with class #{@model_class}"
    end
  end

  class TypeMissing < Error
  end
end

end
end
