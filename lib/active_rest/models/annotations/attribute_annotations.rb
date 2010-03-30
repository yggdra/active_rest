#
# Copyright (c) 2008 Steffen Hiller, released under the MIT license
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

module ActiveRest
module Models
module Annotations

  module AttributeAnnotations #:nodoc:

    #
    # in here we define a chain to let virtual attributes to be magically
    # contactenated with the 'attributes' set
    # NOTE: a virtual_attribute_generator method must be declared in model
    #
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        def attributes_with_virtual_attributes
          attr = attributes_without_virtual_attributes
          if respond_to?(:virtual_attributes_generator)
            attr.merge!( virtual_attributes_generator || {} )
          end
          attr
        end

        alias_method_chain :attributes, :virtual_attributes

        def attribute_names_with_virtual_attributes
          attr = attribute_names_without_virtual_attributes
          attr = attr.concat((self.class.attribute_annotations || {}).keys).collect{|n|n.to_s}
          attr
        end

        alias_method_chain :attribute_names, :virtual_attributes
      end
    end

    module ClassMethods
      attr_reader :attribute_annotations

      def attr_annotate(attribute, annotations ={})
        attribute = attribute.to_s.to_sym
        writer = true
        reader = true
        writer = annotations[:writer] unless annotations[:writer].nil?
        reader = annotations[:reader] unless annotations[:reader].nil?
        annotations.delete :writer
        annotations.delete :reader

        @attribute_annotations = Hash.new if @attribute_annotations.nil?
        if @attribute_annotations.has_key?(attribute)
          @attribute_annotations[attribute].merge!(annotations)
        else
          @attribute_annotations[attribute] = annotations
        end
        build_virtual_accessor(attribute, writer, reader)
      end

      def attr_annotation(attribute, annotation)
        attribute = attribute.to_s.to_sym
        unless @attribute_annotations.nil?
          if @attribute_annotations.has_key?(attribute)
            return @attribute_annotations[attribute][annotation] if @attribute_annotations[attribute].has_key?(annotation)
          end
        end
        nil
      end

      #
      # ritornano i campi specifici impostati con annotation
      #

      def attr_type(attribute)
        return attr_annotation(attribute, :type) unless attr_annotation(attribute, :type).nil?
        return columns_hash[attribute.to_s].type if columns_hash.has_key?(attribute.to_s)
        if reflections.has_key?(attribute)
          return :string # require to_s method
        end
      end

      def attr_caption(attribute)
        return attr_annotation(attribute, :caption) unless attr_annotation(attribute, :caption).nil?
      end

      def attr_search(attribute)
        return attr_annotation(attribute, :search) unless attr_annotation(attribute, :search).nil?
      end

      def attr_controller(attribute)
        attribute = attribute.to_s.to_sym
        return attr_annotation(attribute, :controller) unless attr_annotation(attribute, :controller).nil?
      end

      def attr_value(attribute)
        return attr_annotation(attribute, :value) unless attr_annotation(attribute, :value).nil?
      end

      #
      # map_filter, hash like:
      # attr_annotate :group_id, :alternative_filter => {:refer_to=>:group_label}
      # attr_annotate :group_label, :alternative_filter => {:model=>:group, :field=>:name}
      #
      # is read as, the real group_id (number) field can be queried in two way:
      # - normal query with query_id=1
      # - or query_label='sometext' --> this will trigger a map lookup and a finder with :include
      #   and rewritten conditions to group_table_name.field (name in this example)
      #
      #
      def attr_alternative_filter(attribute)
        return attr_annotation(attribute, :alternative_filter) unless attr_annotation(attribute, :alternative_filter).nil?
      end

      private

      def build_virtual_accessor(attribute, writer = true, reader = true)
        begin
          columns = self.column_names
        rescue
        end
        unless columns && columns.include?(attribute.to_s)
          if !respond_to?(attribute.to_sym) && reader==true
            line = __LINE__
            class_eval %{
              def #{attribute}
                if respond_to?(:virtual_attributes_generator)
                  vattrs = virtual_attributes_generator
                  return vattrs[:#{attribute}].nil? ? @#{attribute} : vattrs[:#{attribute}]
                end
                @#{attribute}
              end
            }, __FILE__, line + 1
          end

          if !respond_to?("#{attribute}=".to_sym) && writer == true
            line = __LINE__
            class_eval %{
              def #{attribute}=(val)
                @#{attribute} = val
              end
            }, __FILE__, line + 1
          end
        end
      end
    end
  end

end
end
end


ActiveRecord::Base.send :include, ActiveRest::Models::Annotations::AttributeAnnotations
