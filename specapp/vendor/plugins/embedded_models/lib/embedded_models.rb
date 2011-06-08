
$:.unshift(File.dirname(__FILE__))

require 'active_record'

module ActiveRecord::Associations::ClassMethods
  @@valid_keys_for_has_many_association << :embedded
  @@valid_keys_for_has_one_association << :embedded << :embedded_in
  @@valid_keys_for_belongs_to_association << :embedded << :embedded_in
end

# patch ActiveRecord serializer to autoinclude embedded objects
module ActiveRecord #:nodoc:
  module Serialization
    class Serializer #:nodoc:

      def add_includes(&block)
        associations = []

        base_only_or_except = { :except => options[:except],
                                :only => options[:only] }

        if include_associations = options.delete(:include)
          include_has_options = include_associations.is_a?(Hash)
          associations = include_has_options ? include_associations.keys : Array(include_associations)
        end

        @record.class.reflections.each { |name, reflection|
          if reflection.options[:embedded]
            associations << reflection.name
          end
        }

        associations.uniq!

        for association in associations
          records = case @record.class.reflect_on_association(association).macro
            when :has_many, :has_and_belongs_to_many
              @record.send(association).to_a
            when :has_one, :belongs_to
              @record.send(association)
            end

          unless records.nil?
            association_options = include_has_options ? include_associations[association] : base_only_or_except
            opts = options.merge(association_options)
            yield(association, records, opts)
          end
        end

        options[:include] = include_associations
      end
    end
  end
end
