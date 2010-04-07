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
#
#

module ActiveRest
  module Finder

    class Expression
      class SyntaxError < StandardError; end
      class InvalidJSON < SyntaxError; end
      class UnknownField < SyntaxError; end
      class UnknownOperand < SyntaxError; end

      attr_accessor :tree
      attr_accessor :model

      def self.from_json(json, model)
        newobj = self.new

        begin
          newobj.tree = ActiveSupport::JSON.decode(json)
        rescue
          raise SyntaxError
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

            raise SyntaxError.new("Attribute '#{attr}' name has invalid chars") if attr =~ /[^a-zA-Z0-9_]/

            raise UnknownField.new("Unknown field '#{attr}'") if !model.columns_hash[attr]

            @sql += model.connection.quote_column_name(attr)
          else
            to_sql_recur(term)
          end
        elsif term.is_a?(Array)
          @sql += '(' + term.map { |x| model.connection.quote(x) }.join(',') + ')'
        end
      end

      def to_sql_recur(tree)

        raise SyntaxError.new("Expected operator for expression #{tree}") if !tree[:o]

        op = tree[:o].upcase
        case op
        when '>', '>=', '<', '<=', '=', '<>', 'LIKE', 'NOT LIKE', 'IN', 'NOT IN', 'AND', 'OR'
          raise SyntaxError.new("Expected operand a for operator #{op}") if !tree[:a]
          raise SyntaxError.new("Expected operand b for operator #{op}") if !tree[:b]

          to_sql_recur_handle_term(tree[:a])
          @sql += ' ' + op + ' '
          to_sql_recur_handle_term(tree[:b])

        when 'IS NULL', 'IS NOT NULL'
          # Unary operator
          raise SyntaxError.new("Expected operand a for operator #{op}") if !tree[:a]
          raise SyntaxError.new("Unexpected operand b for operator '#{op}'") if tree[:b]

          to_sql_recur_handle_term(tree[:a])
          @sql += ' ' + op + ' '

        when 'NOT'
          # Unary operator
          raise SyntaxError.new("Expected operand b for operator #{op}") if !tree[:b]
          raise SyntaxError.new("Unexpected operand a for operator '#{op}'") if tree[:a]

          @sql += ' ' + op + ' '
          to_sql_recur_handle_term(tree[:b])

        else
          raise UnknownOperand
        end
      end
    end

    def self.included(base)
      #:nodoc:
    end

    protected

    #
    # build options for index search
    #
    def update_model_finder_scope

      if params[:filter]
        begin
          expr = Expression.from_json(params[:filter], target_model)
          cond = expr.to_sql(target_model)
        rescue Expression::SyntaxError
          generic_rescue_action(:bad_request)
          return
        end
      end

      target_model.named_scope(:ar_finder_scope, :conditions => cond)

      return nil

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
