
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
    attr_accessor :ignored
    attr_accessor :readable
    attr_accessor :writable

    def initialize(name, interface, h = {})
      @name = name
      @interface = interface

      @human_name = ''
      @meta = {}
      @default = nil
      @notnull = false
      @ignored = false
      @readable = true
      @writable = true

      h.each { |k,v| send("#{k}=", v) }

      if self.class != Attribute
        @type = self.class.name.split('::').last.underscore.to_sym
      end
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
      res[:writable] = @writable
      res[:readable] = @readable

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
      @ignored = attr.ignored
      @readable = attr.readable
      @writable = attr.writable
    end

    def exclude!
      @ignored = true
      @readable = false
      @writable = false
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

      def type(val)
        @attrs[@name].type = val
      end

      def notnull(val)
        @attrs[@name].notnull = val
      end

      def default(val)
        @attrs[@name].default = val
      end

      def exclude!
        @attrs[@name].exclude!
      end

      def ignore!
        @attrs[@name].ignored = true
      end

      def not_writable!
        @attrs[@name].writable = false
      end

      def not_readable!
        @attrs[@name].readable = false
      end
    end

    #
    class Structure < Attribute
    end

    # Reference to another linked but not embedded model. It may come from a has_one or belongs_to
    #
    class Reference < Attribute
      attr_accessor :referenced_class_name

      def definition
        res = super
        res[:referenced_class] = @referenced_class_name
        res
      end
    end

    # EmbeddedModel describes an attribute containing an embedded model
    #
    class EmbeddedModel < Attribute
      attr_accessor :model_class

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
      attr_accessor :model_class

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
      attr_accessor :referenced_class_name

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
