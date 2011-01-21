#
# ActiveRest
#
# Copyright (C) 2008-2011, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

module ActiveRest
module Controller

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
  module Finder

    def self.included(base)
      #:nodoc:
    end

    protected

    class Expression
      class SyntaxError < Exception; end
      class InvalidJSON < SyntaxError; end
      class UnknownField < SyntaxError; end
      class UnknownOperator < SyntaxError; end

      attr_accessor :tree
      attr_accessor :rel

      def self.from_json(json, rel)
        newobj = self.new
        newobj.rel = rel

        begin
          newobj.tree = ActiveSupport::JSON.decode(json)
        rescue
          raise InvalidJSON
        end

        return newobj
      end

      def to_arel
        @tree.symbolize_keys!

        if @tree[:field]
          # Valid for boolean fields
          return rel.scoped.table[@tree[:field]]
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
            raise UnknownField, "Unknown field '#{attr}'" if !rel.columns_hash[attr]

            return rel.table[attr]
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
        when 'ILIKE';       return term_a.matches(term_b)
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
    # given a relation applies filtering from controller's parameters
    #
    def apply_filter_to_relation(rel)

      # If a complex filter expression es present, decode and apply it
      if params[:_filter]
        begin
          rel = rel.where(Expression.from_json(params[:_filter], rel).to_arel)
        rescue Expression::UnknownField => e
          raise UnprocessableEntity.new(e.message)
        end
      end

      # For each parameter matching a column name add an equality relation to the conditions
      params.each do |k,v|
        next if k =~ /^-/

        if rel.table[k]
          rel = rel.where(k => v)
        end
      end

      return rel
    end
  end

end
end
