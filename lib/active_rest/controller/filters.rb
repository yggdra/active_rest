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
  # Filters module implements index action filtering through a filter= URI parameter
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
  module Filters

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
      attr_reader :joins

      def self.from_json(json, rel)
        newobj = self.new
        newobj.rel = rel

        if json.is_a?(String)
          begin
            json = ActiveSupport::JSON.decode(json)
          rescue
            raise InvalidJSON
          end
        end

        newobj.tree = json

        return newobj
      end

      def initialize
        @joins = []
      end

      def to_arel
        @tree.symbolize_keys!

        if @tree[:field]
          # Valid for boolean fields
          return @rel.scoped.table[@tree[:field]]
        else
          return to_arel_recur(@tree)
        end
      end

      private

      def to_arel_recur_handle_term(term)
        if term.is_a?(Hash)
          term.symbolize_keys!

          attr = term[:field]

          if attr
            raise SyntaxError, "Attribute '#{attr}' name has invalid chars" if attr =~ /[^a-zA-Z0-9._]/

            attr_split = attr.split('.')
            if attr_split.count > 1

              raise "Unsupported joins deeper than one level" if attr_split.count > 2

              relation = @rel.reflections[attr_split[0].to_sym]
              raise UnknownField, "Unknown relation #{attr_split[0]}" if !relation

              @joins << attr_split[0]
              attr = attr_split[1..-1].join('.')

              raise UnknownField, "Unknown field '#{attr}'" if !relation.klass.columns_hash[attr]

              return relation.klass.scoped.table[attr]
            else
              raise UnknownField, "Unknown field '#{attr}'" if !@rel.columns_hash[attr]

              return @rel.table[attr]
            end
          else
            return to_arel_recur(term)
          end
        else
          return term
        end
      end

      def to_arel_recur(tree)

        raise SyntaxError, "Expected operator for expression '#{tree}'" if !tree[:o]

        term_a = tree[:a] ? to_arel_recur_handle_term(tree[:a]) : nil
        term_b = tree[:b] ? to_arel_recur_handle_term(tree[:b]) : nil

        op = tree[:o].upcase
        case op
        when 'IS NULL';     return term_a.eq(nil)
        when 'IS NOT NULL'; return term_a.not_eq(nil)
        when '>';           return term_a.gt(term_b)
        when '>=';          return term_a.gteq(term_b)
        when '<';           return term_a.lt(term_b)
        when '<=';          return term_a.lteq(term_b)
        when '=';           return term_a.eq(term_b)
        when '<>';          return term_a.not_eq(term_b)
        when 'ILIKE';       return term_a.matches(term_b)
        when 'NOT ILIKE';   return term_a.does_not_match(term_b)
        when 'IN';          return term_a.in(term_b)
        when 'IN ANY';      return term_a.in_any(term_b)
        when 'IN ALL';      return term_a.in_all(term_b)
        when 'NOT IN';      return term_a.not_in(term_b)
        when 'NOT IN ANY';  return term_a.not_in_any(term_b)
        when 'NOT IN ALL';  return term_a.not_in_all(term_b)
        when 'AND';         return term_a.and(term_b)
        when 'OR';          return term_a.or(term_b)
        else
          raise UnknownOperator, "Unknown operator '#{op}'"
        end
      end
    end

    # For each parameter matching a column name add an equality condition to the relation
    #
    def apply_simple_filter_to_relation(rel)
      params.each do |k,v|
        next if k[0] == '_'

        next if !rel.klass.columns_hash[k]

        (attr, rel) = model.nested_attribute(k, rel)
        rel = rel.where(attr.eq(v))
      end

      rel
    end

    #
    # given a relation applies filtering from controller's parameters
    #
    def apply_json_filter_to_relation(rel)

      # If a complex filter expression es present, decode and apply it
      if params[:filter]
        begin
          exp = Expression.from_json(params[:filter], rel)
          rel = rel.where(exp.to_arel)

          # If the expression references linked relations, join them. 'includes' *should* produce a LEFT OUTER JOIN
          # so the expression would match if the linked relation is missing
          #
          exp.joins.uniq.each do |join|
            rel = rel.includes(join.to_sym)
          end
        rescue Expression::SyntaxError => e
          raise ActiveRest::Exception::BadRequest.new(e.message)
        end
      end

      rel
    end

    def apply_search_to_relation(rel, search_in = nil)
      if params[:search] && search_in
        expr = nil

        search_in.each do |x|
          (attr, rel) = model.nested_attribute(x, rel)
          e = attr.matches('%' + params[:search] + '%')
          expr = expr ? expr.or(e) : e
        end

        rel = rel.where(expr)
      end

      rel
    end

  end

end
end
