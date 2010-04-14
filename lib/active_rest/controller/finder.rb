#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Finder
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: base.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
# Finder module implements index action filtering through a filter= URI parameter
#
# The filter parameter should contain a JSON serialized tree structure representing the expression
# Each node can be a String, a Numeric, an Array and a Hash.
#
# - Strings, Numeric and Arrays are quoted and inserted into the SQL expression.
#
# - Hashes may:
#   - Contain just one key "field". The value is inserted into the SQL as a field name.
#   - Contain "o" and "a" and/or "b" keys. In this case the Hash represent an expression, "a" and "b" are the
#     two terms, "o" is an operator. "a" or "b" may be missing in case of unary operators.
#
# Supported operators:
#
# Binary: >, >=, <, <=, =, <>, LIKE, NOT LIKE, IN, NOT IN, AND, OR
# Unary: IS NULL, IS NOT NULL, NOT
#

module ActiveRest
module Controller
  module Finder

    def self.included(base)
      #:nodoc:
    end

    protected

    class Expression
      class SyntaxError < StandardError; end
      class InvalidJSON < SyntaxError; end
      class UnknownField < SyntaxError; end
      class UnknownOperator < SyntaxError; end

      attr_accessor :tree
      attr_accessor :model

      def self.from_json(json, model)
        newobj = self.new

        begin
          newobj.tree = ActiveSupport::JSON.decode(json)
        rescue
          raise InvalidJSON
        end

        newobj.model = model
        return newobj
      end

      def to_sql(model)
        @sql = ''
        @pars = []

        @tree.symbolize_keys!

        if @tree[:field]
          to_sql_recur_handle_term(@tree)
        else
          to_sql_recur(@tree)
        end

        return [@sql] + @pars
      end

      private

      def to_sql_recur_handle_term(term)
        if term.is_a?(String) || term.is_a?(Numeric)
          @sql += '?'
          @pars << term
        elsif term.is_a?(Hash)
          term.symbolize_keys!

          if term[:field]

            attr = term[:field]

            raise SyntaxError, "Attribute '#{attr}' name has invalid chars" if attr =~ /[^a-zA-Z0-9_]/

            raise UnknownField, "Unknown field '#{attr}'" if !model.columns_hash[attr]

            @sql += model.connection.quote_column_name(attr)
          else
            to_sql_recur(term)
          end
        elsif term.is_a?(Array)
          @sql += '(' + term.map { |x| model.connection.quote(x) }.join(',') + ')'
        end
      end

      def to_sql_recur(tree)

        raise SyntaxError, "Expected operator for expression '#{tree}'" if !tree[:o]

        op = tree[:o].upcase
        case op
        when '>', '>=', '<', '<=', '=', '<>', 'LIKE', 'NOT LIKE', 'IN', 'NOT IN', 'AND', 'OR'
          raise SyntaxError, "Expected operand a for operator '#{op}'" if !tree[:a]
          raise SyntaxError, "Expected operand b for operator '#{op}'" if !tree[:b]

          to_sql_recur_handle_term(tree[:a])
          @sql += ' ' + op + ' '
          to_sql_recur_handle_term(tree[:b])

        when 'IS NULL', 'IS NOT NULL'
          # Unary operator
          raise SyntaxError, "Expected operand a for operator '#{op}'" if !tree[:a]
          raise SyntaxError, "Unexpected operand b for operator '#{op}'" if tree[:b]

          to_sql_recur_handle_term(tree[:a])
          @sql += ' ' + op + ' '

        when 'NOT'
          # Unary operator
          raise SyntaxError, "Expected operand b for operator '#{op}i" if !tree[:b]
          raise SyntaxError, "Unexpected operand a for operator '#{op}'" if tree[:a]

          @sql += ' ' + op + ' '
          to_sql_recur_handle_term(tree[:b])

        else
          raise UnknownOperator, "Unknown operator '#{op}'"
        end
      end
    end

    #
    # build options for index search
    #
    def get_finder_relation

      if params[:filter]
        begin
          expr = Expression.from_json(params[:filter], target_model)
          cond = expr.to_sql(target_model)
        end
      end

      return target_model.where(cond)


##      options = {
##        :extra_conditions => extra_conditions.nil? ? {} : extra_conditions,
##        :condition_parent => condition_parent,
##        :criteria_parent => criteria_parent,
##        :order_parent => order_parent,
##        :joins => {:reflections => joins[0], :fields => joins[1]},
##        :target_model_to_underscore => target_model_to_underscore,
##        :polymorphic => index_options.has_key?(:polymorphic) ? index_options[:polymorphic] : []
##        # add here other options that can be setted per controller
##      }
    end

end
end
end
