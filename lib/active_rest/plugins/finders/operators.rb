#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Plugins::Finders
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>,
#          Angelo Grossini <angelo@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: operators.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Plugins
module Finders

  module Operators

    def self.registry_filters
      return ['filter']
    end

    #
    # This method is called by ActiveRest::Helpers::Pagination::Core
    #
    #
    # ARGUMENTS
    #
    # example
    # ?filter=[[field,operator,value],[field,operator,value]]
    # operator:
    # eq: field in (value[s])
    # not: field not in (value[s])
    # gt: field > value
    # gte: field >= value
    # lte: field <= value
    # lt: field < value
    # begins: field like value%
    # contains: field like %value%
    # ends: field like %value
    #
    def self.build_conditions(target_model, params, options={})

      # fields to ignore
      # hash of :field => [model1, model2....]
      forbidden_fields = {}

      unless options[:criteria_parent].blank?
        key = options[:criteria_parent].keys[0]
        forbidden_fields[key.to_s] ||= []
        forbidden_fields[key.to_s] << target_model
      end

      options[:extra_conditions].keys.each do  |k|
        field = k.to_s
        field = k.to_s.gsub(/^[^\[]*\[([^\]]*)\]$/){$1} if k.to_s.include?('[')
        model = target_model
        field = (k.to_s.gsub(/^([^\[]*)\[[^\]]+\]$/){$1}).downcase.camelize.constantize if k.to_s.include?('[')
        forbidden_fields[k.to_s] ||= []
        forbidden_fields[k.to_s] << model
      end unless options[:extra_conditions].blank?

      filters = []
      filters = ActiveSupport::JSON::decode(params[:filter]) unless params[:filter].blank?

      joins = options[:joins] ? options[:joins][:reflections] || [] : []
      join_fields = options[:joins] ? options[:joins][:fields] || {} : {}

      sql_string = []
      sql_values = {}

      tmp = {}
      filters.each do | filter |
        # "model[field]" => "field"
        column = filter[0].gsub(/^[^\[]*\[([^\]]*)\]$/){$1} if filter[0].include?('[')
        column = filter[0] unless filter[0].include?('[')
        # "model[field]" => "model"
        model_name = (filter[0].gsub(/^([^\[]*)\[[^\]]+\]$/){$1}).downcase if filter[0].include?('[')

        is_join = true if !model_name && join_fields.has_value?(target_model.connection.quote_column_name(column))

        model = target_model.reflections[model_name.to_sym].klass if model_name && joins.include?(model_name.to_sym)
        model = target_model if !model && (!model_name || model_name == options[:target_model_to_underscore]) #.class_name)

        # no model found.... skip
        next if model.nil?

        # forbidden fields, passed as options[:criteria_parent] and/or options[:extra_conditions]
        next if forbidden_fields.keys.include?(column) && forbidden_fields[column].include?(model)

        # skip if column not found in model or, if model not specified, field is not part of a join
        next unless model.column_names.include?(column) || is_join

        #filter operator not found.... skip
        next unless %w(eq not begins contains ends lt lte gte gt).include?(filter[1])

        field = "#{model.quoted_table_name}.#{target_model.connection.quote_column_name(column)}"
        # if join, replace the alias with `model`.`column`
        field = join_fields.index(target_model.connection.quote_column_name(column)) if is_join

        tmp[field] ||= {filter[1] => []}
        tmp[field][filter[1]] ||= []
        tmp[field][filter[1]] << filter[2]
      end

      tmp.each do |field, filter|
        filter.each do | condition, values |
          symbol = "#{field.gsub(/[^a-zA-Z0-9\-_]/, '')}#{rand(1000000)}".to_sym
          case condition
          when 'eq','not'
            sql_string << "#{field} #{condition == 'not' ? 'NOT' : ''} IN (:#{symbol})"
            sql_values[symbol] = values
          when 'begins','ends'
            conds = []
            vals = []
            values.each do |val|
              conds << "#{field} LIKE :#{symbol}"
              sql_values[symbol] = condition == 'begins' ? "#{val}%" : "%#{val}"
              symbol = "#{field.gsub(/[^a-zA-Z0-9\-_]/, '')}#{rand(1000000)}".to_sym
            end
            sql_string << "(#{conds.join(' OR ')})"
          when 'contains'
            conds = []
            values.each do |val|
              conds << "#{field} LIKE :#{symbol}"
              sql_values[symbol] = "%#{val}%"
              symbol = "#{field.gsub(/[^a-zA-Z0-9\-_]/, '')}#{rand(1000000)}".to_sym
            end
            sql_string << "(#{conds.join(' OR ')})"
          when 'gt'
            sql_string << "#{field} > :#{symbol}"
            sql_values[symbol] = values.sort.first
          when 'gte'
            sql_string << "#{field} >= :#{symbol}"
            sql_values[symbol] = values.sort.first
          when 'lt'
            sql_string << "#{field} < :#{symbol}"
            sql_values[symbol] = values.sort.last
          when 'lte'
            sql_string << "#{field} <= :#{symbol}"
            sql_values[symbol] = values.sort.last
          end
        end
      end

      retval = {}

      if sql_string.length > 0 && sql_values.length > 0
        retval = {:conditions => ["(#{sql_string.join(') AND (')})", sql_values]}
      end

      if !options[:criteria_parent].blank? || !options[:extra_conditions].blank?
        retval = {:conditions => ["", {}]} if retval[:conditions].blank?
        unless options[:criteria_parent].blank?
          retval[:conditions][0] = options[:condition_parent] + (retval[:conditions][0].blank? ? '' : ' AND ') + retval[:conditions][0]
          retval[:conditions][1].merge!(options[:criteria_parent])
        end

        unless options[:extra_conditions].blank?
          options[:extra_conditions].each do | key, value |
            field = key.to_s
            column = field
            column = field.gsub(/^[^\[]*\[([^\]]*)\]$/){$1} if field.include?('[')
            model = target_model
            model = (field.gsub(/^([^\[]*)\[[^\]]+\]$/){$1}).downcase.camelize.constantize if field.include?('[')

            key = field.gsub(/[^a-zA-Z0-9-_]*/, '_')

            retval[:conditions][0] = "#{model.quoted_table_name}.#{model.connection.quote_column_name(column)} = :{key}" + (retval[:conditions][0].blank? ? '' : ' AND ') + retval[:conditions][0]
            retval[:conditions][1][key.to_sym] = value
          end
        end
      end

      return retval
    end
  end

end
end
end
