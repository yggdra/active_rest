require 'active_rest/model/interface/attribute'

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
          else
            @attrs[name] = Attribute::PolymorphicReference.new(name, self)
          end
        else
          if reflection.options[:embedded]
            @attrs[name] =
              Attribute::EmbeddedModel.new(name, self, :model_class => reflection.class_name)

            # Hide embedded foreign key column
            fkn = reflection.foreign_key.to_sym
            if @attrs[fkn]
              @attrs[fkn].excluded = true
            else
              @attrs_defined_in_code[fkn] ||= Attribute.new(fkn, @interface)
              @attrs_defined_in_code[fkn].excluded = true
            end
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

    attrs.select { |k,v| !v.excluded }.each do |attrname,attr|
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
      raise AttributeNotWriteable.new(obj, valuename) if !attr.writeable

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
          record.destroy if record

          if @allow_polymorphic_creation && value.has_key('_type') && value['_type']
            newrecord = value['_type'].constantize.new
          else
            newrecord = obj.send("build_#{valuename}")
          end

          newrecord.interfaces[@name].apply_creation_attributes(newrecord, value);
        end

      when Attribute::UniformModelsCollection

        association = obj.send(valuename)

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
    else
      type
    end
  end


  class DSL
    def initialize(interface)
      @interface = interface
    end

    def attribute(name, &block)
      a = @interface.attrs_if_defined || @interface.attrs_defined_in_code

      a[name] ||= Attribute.new(name, @interface)
      Attribute::DSL.new(@interface, a, name).instance_eval(&block)
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
      "Attribute #{@attribute_name} in class #{@model_class} is not writeable"
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
