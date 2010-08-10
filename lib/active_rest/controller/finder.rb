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
        newobj.model = model

        begin
          newobj.tree = ActiveSupport::JSON.decode(json)
        rescue
          raise InvalidJSON
        end

        return newobj
      end

      def to_arel(model)
        @tree.symbolize_keys!

        if @tree[:field]
          # Valid for boolean fields
          return model.scoped.table[@tree[:field]]
        else
          return to_arel_recur(@tree)
        end
      end

      private

      def to_arel_recur_handle_term(term)
        if term.is_a?(String) || term.is_a?(Numeric) || term.is_a?(Array)
          return term
        elsif term.is_a?(Hash)
          term.symbolize_keys!

          attr = term[:field]

          if attr
            raise SyntaxError, "Attribute '#{attr}' name has invalid chars" if attr =~ /[^a-zA-Z0-9_]/
            raise UnknownField, "Unknown field '#{attr}'" if !model.columns_hash[attr]

            return model.scoped.table[attr]
          else
            return to_arel_recur(term)
          end
        end
      end

      def to_arel_recur(tree)

        raise SyntaxError, "Expected operator for expression '#{tree}'" if !tree[:o]

        term_a = tree[:a] ? to_arel_recur_handle_term(tree[:a]) : nil
        term_b = tree[:b] ? to_arel_recur_handle_term(tree[:b]) : nil

        op = tree[:o].upcase
        case op
        when 'IS NULL';     return term_a.eq(nil)
        when 'IS NOT NULL'; return term_a.not(nil)
        when '>';           return term_a.gt(term_b)
        when '>=';          return term_a.gteq(term_b)
        when '<';           return term_a.lt(term_b)
        when '<=';          return term_a.lteq(term_b)
        when '=';           return term_a.eq(term_b)
        when '<>';          return term_a.not_eq(term_b)
        when 'LIKE';        return term_a.matches(term_b)
        when 'IN';          return term_a.in(term_b)
        when 'AND';         return term_a.and(term_b)
        when 'OR';          return term_a.or(term_b)
#        when 'NOT IN';
#          return term_a.notin(term_b)
#        when 'NOT LIKE'
#          return term_a.notlike(term_b)
##        when 'NOT'
##          # Unary operator
        else
          raise UnknownOperator, "Unknown operator '#{op}'"
        end
      end
    end

    #
    # build options for index search
    #
    def build_finder_relation

      # If a complex filter expression es present, decode and apply it
      if params[:_filter]
        cond = Expression.from_json(params[:_filter], model).to_arel(model)
      end

      # For each parameter matching a column name add an equality relation to the conditions
      params.each do |k,v|
        next if k =~ /^-/

        if attr = model.scoped.table[k]
          raise UnknownField, "Unknown field '#{attr}'" if !attr

          if cond
            cond = cond & attr.eq(v)
          else
            cond = attr.eq(v)
          end
        end
      end

      return model.where(cond)
    end
  end

end
end
