require 'active_rest/model/interface/attribute'

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

  attr_reader :delayed_attrs

  def initialize(name, model, opts = {})
    @name = name
    @opts = opts
    @delayed_attrs = {}
    @views = {}
    @activerecord_autoinit = true
    @attrs = nil

    @allow_polymorphic_creation = false

    self.model = model
  end

  def model=(model)
    @model = model

    @activerecord_autoinit = false if !(model <= ActiveRecord::Base)
  end

  def initialize_copy(source)
    if @attrs
      @attrs = @attrs.clone
      @attrs.each { |k,v| (@attrs[k] = v.clone).interface = self }
    end

    if @delayed_attrs
      @delayed_attrs = @delayed_attrs.clone
      @delayed_attrs.each { |k,v| (@delayed_attrs[k] = v.clone).interface = self }
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
      @attrs = @delayed_attrs
      @delayed_attrs = nil
    end

    @attrs
  end

  def mark_attr_to_be_excluded(name)
    if @attrs[name]
      @attrs[name].exclude!
    else
      @delayed_attrs[name] ||= Attribute.new(name, @interface)
      @delayed_attrs[name].exclude!
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
        )
    end

    @model.reflections.each do |name, reflection|

      case reflection.macro
      when :composed_of
        @attrs[name] =
          Attribute::Structure.new(name, self, :type => reflection.macro, :model_class => reflection.options[:class_name])

        # Hide attributes composing the structure
        reflection.options[:mapping].each { |x| mark_attr_to_be_excluded(x[0].to_sym) }

      when :belongs_to, :has_one
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
              Attribute::EmbeddedModel.new(name, self, :model_class => reflection.class_name)

            # Hide embedded foreign key column
            mark_attr_to_be_excluded(reflection.foreign_key.to_sym)
          else
            @attrs[name] =
              Attribute::Reference.new(name, self, :referenced_class_name => reflection.class_name)
          end
        end

      when :has_many
        if reflection.options[:embedded]
          @attrs[name] =
            Attribute::UniformModelsCollection.new(name, self, :model_class => reflection.class_name)
        else
          @attrs[name] =
            Attribute::UniformReferencesCollection.new(name, self,
              :referenced_class_name => reflection.class_name,
              :foreign_key => (!reflection.is_a?(ActiveRecord::Reflection::ThroughReflection) ? reflection.foreign_key : nil),
              :foreign_type => (!reflection.is_a?(ActiveRecord::Reflection::ThroughReflection) ? reflection.type : nil),
              :as => reflection.options[:as])
        end

      else
        raise "Usupported reflection of type '#{reflection.macro}'"
      end
    end

    @delayed_attrs.each do |attrname, attr|
      if @attrs[attrname]
        @attrs[attrname].apply(attr)
      else
        @attrs[attrname] = attr
      end
    end

    @delayed_attrs = nil

    @attrs
  end

  def attribute(name, type = nil, &block)
    a = @attrs || @delayed_attrs

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
    attrs.select { |k,v| view.attr_visible?(k) && v.readable }.each do |attrname,attr|
      attrname = attrname.to_sym
      viewdef = view.definition[attrname]
      viewinc = viewdef ? viewdef.include : false
      subview = viewdef ? viewdef.subview : nil

      case attr
      when Model::Interface::Attribute::Reference
        incs << attrname if viewinc
      when Model::Interface::Attribute::EmbeddedModel
        incs << attrname
      when Model::Interface::Attribute::UniformModelsCollection
        # eager loading with limit is not supported:
        # http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html
        #

        if !viewdef || !viewdef.limit
          subinc = attr.model_class.constantize.interfaces[@name].eager_loading_hints(:view => subview)
          incs << (subinc.any? ? { attr.name_in_model => subinc } : attr.name_in_model)
        end
      when Model::Interface::Attribute::UniformReferencesCollection
        if viewinc && !viewdef.limit
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

  def ar_serializable_hash(obj, opts = {})

    view = opts[:view]

    if view.is_a?(Symbol)
      view = @views[view]
      raise ViewNotFound, "View #{opts[:view]} not found" if !view
    end

    view ||= View.new(:anonymous)

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
    attrs.select { |k,v| view.attr_visible?(k) && v.readable }.each do |attrname,attr|
      attrname = attrname.to_sym
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

      if with_perms
        perms[attrname] ||= {}
        perms[attrname][:read] = true
        perms[attrname][:write] = true
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
        :read => true,
        :write => true,
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

  def apply_model_attributes(obj, values)
    values.each do |valuename, value|

      valuename = valuename.to_sym
      attr = attrs[valuename]

      if valuename == :_type
        next if !value
        next if @allow_polymorphic_creation && value.constantize <= obj.class
        next if value.constantize == obj.class

        raise ClassDoesNotMatch.new(obj.class, value.constantize)
      end
      next if valuename == :id

      raise AttributeNotFound.new(obj, valuename) if !attr
      next if attr.ignored
      raise AttributeNotWriteable.new(obj, valuename) if !attr.writable

      case attr
      when Attribute::Reference
      when Attribute::EmbeddedModel
        record = obj.send(valuename)

        if !value || value['_destroy']
          # DESTROY
          record.mark_for_destruction if record
        elsif record && value['id'] && value['id'] != 0 && record.id == value['id']
          # UPDATE
          record.interfaces[@name].apply_update_attributes(record, value)
        else
          # CREATE

          # We have to do this since it is embedded
          record.mark_for_destruction if record

          if @allow_polymorphic_creation && value.has_key('_type') && value['_type']
            newrecord = value['_type'].constantize.new
          else
            newrecord = obj.send("build_#{valuename}")
          end

          newrecord.interfaces[@name].apply_creation_attributes(newrecord, value)
        end

      when Attribute::UniformModelsCollection

        association = obj.association(valuename)

        existing_records = if association.loaded?
          association.target
        else
          ids = value.map {|a| a['id'] || a[:id] }.compact
          ids.empty? ? [] : association.scoped.where(association.klass.primary_key => ids)
        end

        value.each do |attributes|
          attributes = attributes.with_indifferent_access

          if attributes['id'].blank? || attributes['id'] == 0
            # CREATE

            if attributes['_type'] && attr.model_class.constantize.interfaces[@name].allow_polymorphic_creation
              newrecord = attributes[:_type].constantize.new
              newrecord.interfaces[@name].apply_creation_attributes(newrecord, attributes)
              association.concat(newrecord)
            else
              newrecord = association.build
              newrecord.interfaces[@name].apply_creation_attributes(newrecord, attributes)
            end

          elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes['id'].to_s }

            unless association.loaded?
              target_record = association.target.detect { |record| record == existing_record }

              if target_record
                existing_record = target_record
              else
                association.add_to_target(existing_record)
              end
            end

            if attributes['_destroy']
              # DESTROY
              existing_record.destroy
            else
              # UPDATE
              existing_record.interfaces[@name].apply_update_attributes(existing_record, attributes)
            end
          else
            raise AssociatedRecordNotFound.new
          end
        end
      when Attribute::UniformReferencesCollection
      when Attribute::EmbeddedPolymorphicModel
      when Attribute::PolymorphicReference
      when Attribute::PolymorphicModelsCollection
      when Attribute::PolymorphicReferencesCollection

      when Attribute::Structure, Attribute
        obj.send("#{valuename}=", value)
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

  class AssociatedRecordNotFound < StandardError
  end

  class AttributeError < StandardError
    attr_accessor :model_class
    attr_accessor :attribute_name

    def initialize(model_class, attribute_name)
      @attribute_name = attribute_name
    end
  end

  class AttributeNotWriteable < AttributeError
    def to_s
      "Attribute #{@attribute_name} in class #{@model_class} is not writable"
    end
  end

  class AttributeNotFound < AttributeError
    def to_s
      "Attribute #{@attribute_name} in class #{@model_class} not found"
    end
  end

  class ClassDoesNotMatch < StandardError
    attr_accessor :model_class
    attr_accessor :type

    def initialize(model_class, type)
      @model_class = model_class
      @model_type = type
    end

    def to_s
      "Type #{@model_type} does not match with class #{@model_class}"
    end
  end

end

end
end
