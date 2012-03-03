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
  attr_reader :attrs_defined_in_code
  attr_accessor :allow_polymorphic_creation

  def initialize(name, model, opts = {})
    @name = name
    @model = model
    @opts = opts
    @attrs = nil
    @attrs_defined_in_code = {}

    @allow_polymorphic_creation = false
  end

  def model=(model)
    @model = model
    @attrs = nil
  end

  def initialize_copy(source)
    if @attrs
      @attrs = @attrs.clone
      @attrs.each { |k,v| (@attrs[k] = v.clone).interface = self }
    end

    @attrs_defined_in_code = @attrs_defined_in_code.clone
    @attrs_defined_in_code.each { |k,v| (@attrs_defined_in_code[k] = v.clone).interface = self }

    super
  end

  def attrs
    @attrs || initialize_attrs
  end

  def attrs_if_defined
    @attrs
  end


  def mark_attr_to_be_excluded(name)
    if @attrs[name]
      @attrs[name].exclude!
    else
      @attrs_defined_in_code[name] ||= Attribute.new(name, @interface)
      @attrs_defined_in_code[name].exclude!
    end
  end

  def initialize_attrs
    @attrs = {}

    @model.columns.each do |column|
      name = column.name.to_sym
      @attrs[name] =
        Attribute.new(name, self,
          :type => map_column_type(column.type),
          :default => column.default,
          :notnull => !column.null,
        )
    end

    @model.reflections.each do |name, reflection|

      case reflection.macro
      when :composed_of
        @attrs[name] =
          Attribute::Structure.new(name, self, :type => reflection.macro)

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
            Attribute::UniformReferencesCollection.new(name, self, :referenced_class_name => reflection.class_name)
        end

      else
        raise "Usupported reflection of type '#{reflection.macro}'"
      end
    end

    @attrs_defined_in_code.each do |attrname, attr|
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

  def ar_serializable_hash(obj, opts = {})

    view = opts[:view] || View.new(:default)
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
        val = obj.send(attrname)
        values[attrname] = (val.respond_to?(:ar_serializable_hash) ? val.ar_serializable_hash(@name, opts) : nil) ||
                           (val.respond_to?(:to_hash) ? val.to_hash : nil) ||
                           (val.respond_to?(:to_s) ? val.to_s : nil)
      when Model::Interface::Attribute::Reference
        if viewinc
          val = obj.send(attrname)
          values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
        end
      when Model::Interface::Attribute::EmbeddedModel
        val = obj.send(attrname)
        values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
      when Model::Interface::Attribute::UniformModelsCollection
        vals = obj.send(attrname)
        if viewdef
          vals = vals.limit(viewdef.limit) if viewdef.limit
          vals = vals.order(viewdef.order) if viewdef.order
        end
        values[attrname] = vals.map { |x| x.ar_serializable_hash(@name, opts.merge(:view => subview)) }
      when Model::Interface::Attribute::UniformReferencesCollection
        if viewinc
          vals = obj.send(attrname)
          if viewdef
            vals = vals.limit(viewdef.limit) if viewdef.limit
            vals = vals.order(viewdef.order) if viewdef.order
          end
          values[attrname] = vals.map { |x| x.ar_serializable_hash(@name, opts.merge(:view => subview)) }
        end
      when Model::Interface::Attribute::EmbeddedPolymorphicModel
        val = obj.send(attrname)
        values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
      when Model::Interface::Attribute::PolymorphicReference
        if viewinc
          val = obj.send(attrname)
          values[attrname] = val ? val.ar_serializable_hash(@name, opts.merge(:view => subview)) : nil
        else
          ref = obj.association(attrname).reflection
          values[attrname] = { :id => obj.send(ref.foreign_key), :_type => obj.send(ref.foreign_type) }
        end
      when Model::Interface::Attribute::PolymorphicModelsCollection
      when Model::Interface::Attribute::PolymorphicReferencesCollection
      else
        val = obj.send(attrname)

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
        raise ClassDoesNotMatch.new(obj.class, value.constantize) if value && value.constantize != obj.class
        next
      end
      next if valuename == :id

      raise AttributeNotFound.new(obj, valuename) if !attr
      next if attr.ignored
      raise AttributeNotWriteable.new(obj, valuename) if !attr.writable

      case attr
      when Attribute::Reference
      when Attribute::EmbeddedModel
        record = obj.send(valuename)

        if value['_destroy']
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

          newrecord.interfaces[@name].apply_creation_attributes(newrecord, value);
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
              association << newrecord
            else
              newrecord = association.build
            end

            newrecord.interfaces[@name].apply_creation_attributes(newrecord, attributes);

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
              existing_record.mark_for_destruction
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
    else
      type
    end
  end


  class DSL
    def initialize(interface)
      @interface = interface
    end

    def attribute(name, type = nil, &block)
      a = @interface.attrs_if_defined || @interface.attrs_defined_in_code

      if type
        begin
          a[name] ||= "ActiveRest::Model::Interface::Attribute::#{type}".constantize.new(name, @interface)
        rescue NameError
          a[name] ||= Attribute.new(name, @interface, :type => type.split('::').last.underscore.to_sym)
        end
      else
        a[name] ||= Attribute.new(name, @interface)
      end

      a[name].instance_exec(&block) if block
    end

    def allow_polymorphic_creation
      @interface.allow_polymorphic_creation = true
    end
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
      "Type #{@type} does not match with class #{@model_class}"
    end
  end

end

end
end
