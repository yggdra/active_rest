
module ActiveRest
module Model

class Interface

  # Base class for attributes
  #
  class Attribute

    attr_accessor :name
    attr_accessor :type
    attr_accessor :interface
    attr_accessor :human_name
    attr_accessor :default
    attr_accessor :notnull
    attr_accessor :meta
    attr_accessor :excluded
    attr_accessor :ignored
    attr_accessor :readable
    attr_accessor :writeable

    def initialize(name, interface, h = {})
      @name = name
      @interface = interface

      if self.class != Attribute
        @type = self.class.name.split('::').last.underscore.to_sym
      else
        @type = h[:type]
      end

      @human_name ||= h[:human_name]
      @meta = h[:meta] || {}
      @default = h[:default] || nil
      @notnull = h[:notnull] || false
      @excluded = h[:excluded] || false
      @ignored = h[:ignored] || false
      @readable = h[:readable] || true
      @writeable = h[:writeable] || true
    end

    def initialize_copy(source)
      super
      @meta = @meta.clone if @meta
    end

    def definition
      res = { :type => type }
      res[:human_name] = @human_name if @human_name
      res[:default] = @default if @default
      res[:notnull] = true if @notnull
      res[:meta] = @meta if !@meta.empty?
      res[:writeable] = false if !@writeable
      res[:readable] = false if !@readable

      res[:edit_on_creation] = true
      res[:visible_on_creation] = true

      res[:after_creation_perms] = {
        :write => true,
        :read => true,
      }

      res
    end

    def apply(attr)
      # type ?

      @human_name = attr.human_name
      @meta.merge!(attr.meta)
      @excluded = attr.excluded
      @ignored = attr.ignored
      @readable = attr.readable
      @writeable = attr.writeable
    end

    class DSL
      def initialize(interface, attrs, name)
        @interface = interface
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

      def type(type)
        @attrs[@name].type = type
      end

      def exclude!
        @attrs[@name].excluded = true
      end

      def ignore!
        @attrs[@name].ignored = true
      end

      def read_only!
        @attrs[@name].writeable = false
      end

      def write_only!
        @attrs[@name].readable = false
      end
    end

    #
    class Structure < Attribute
    end

    # Reference to another linked but not embedded model. It may come from a has_one or belongs_to
    #
    class Reference < Attribute
      def initialize(name, interface, h = {})
        super

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
      def initialize(name, interface, h = {})
        super

        @model_class = h[:model_class]
      end

      def definition
        res = super

        if !@model_class.constantize.interfaces[@interface.name]
          raise "Missing interface #{@interface.name} from model #{@model_class}"
        end

        res[:schema] = @model_class.constantize.interfaces[@interface.name].schema
        res
      end
    end

    # UniformModelsCollection is a collection of objects of the same type
    #
    class UniformModelsCollection < Attribute
      def initialize(name, interface, h = {})
        super

        @model_class = h[:model_class]
      end

      def definition
        res = super

        if !@model_class.constantize.interfaces[@interface.name]
          raise "Missing interface #{@interface.name} from model #{@model_class}"
        end

        res[:schema] = @model_class.constantize.interfaces[@interface.name].schema

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
      def initialize(name, interface, h = {})
        super

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
  end

end

end
end
