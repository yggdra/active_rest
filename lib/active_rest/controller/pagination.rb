#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Helpers::Pagination::Base
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
module Controller
  module Pagination

    #
    # this module handles conditions, sorting and paginations decoding the incoming json (it describes the filters),
    # then store in session the parameters used to run the query
    #

    def self.included(base)
      #:nodoc:
    end

    protected

    #
    # update pagination state and save it
    #
    def update_pagination_state
#      model_klass = (restraining_model.is_a?(Class) || restraining_model.nil? ? restraining_model : restraining_model.to_s.classify.constantize)
#      pagination_state = previous_pagination_state(model_klass)

      if params[:pag_persistant]
        load_pagination_state
      else
        @pagination = {}
      end

      dir = nil
      if params[:dir]
        dir = params[:dir].to_s.upcase
        raise BadRequest.new("Invalid sort direction #{dir}") unless %w(ASC DESC).include?(dir)
      end

      offset = params[:start] ? params[:start].to_i : nil
      limit = params[:limit] ? params[:limit].to_i : nil

      @pagination.merge!({
        # fields may be passed as 'object[attr]'
        :sort_field => (params[:sort] || @pagination[:sort_field] || 'id').sub(/(\A[^\[]*)\[([^\]]*)\]/,'\2'),
        :sort_direction => (dir || @pagination[:sort_direction]).to_s.upcase,
        :offset => offset || @pagination[:offset] || 0,
        :limit => limit || @pagination[:limit] || 100 # FIXME ActiveRest::Pagination.default_page_size
      })

# This should be done by our caller
#      # allow only valid sort_fields matching column names of the given model ...
#      unless model_klass.nil? || model_klass.column_names.include?(@pagination[:sort_field])
#        @pagination.delete(:sort_field)
#        @pagination.delete(:sort_direction)
#      end

      if params[:pag_persistant]
        save_pagination_state
      end
    end

    def build_pagination_relation
      rel = model.limit(@pagination[:limit]).offset(@pagination[:offset])
      rel = rel.order(@pagination[:sort_field] + ' ' + @pagination[:sort_direction]) if @pagination[:sort_field]
      rel
    end

    private

#    #
#    # lookup for parent id; if found fill in a condition for finder method
#    #
#    def standard_lookup_for_parent_object
#      cond = nil
#      criteria = {}
#      order = nil
#
#      route = ActionController::Routing::Routes.find_route(request.path, {:method => request.method})
#
#      segments = route.segments.select do | seg |
#        !seg.is_a?(ActionController::Routing::DividerSegment)
#      end
#
#      # guess....
#      # assume (something)_id sia l'id del parent model
#      parent_id = nil
#      segments.reverse.each do | seg |
#        parent_id = seg if seg.is_a?(ActionController::Routing::DynamicSegment) && seg.respond_to?(:key) && /^.+_id?/.match(seg.key.to_s) && !params[seg.key].blank?
#        break if parent_id
#      end
#      return nil, {}, nil unless parent_id
#
#      # se le route sono sane, assomiglieranno a /namespace/parent_controller/parent_id/association/......
#      parent_controller = segments[segments.index(parent_id) - 1]
#      association = segments[segments.index(parent_id) + 1]
#
#      resource = ActiveRest::Helpers::Routes::Mapper::ROUTES[parent_controller.value.to_sym][:resource]
#
#      # !!!! il modello salvato nella resource è valid sono la prima volta !!!
#      parent_model = resource.options[:model].to_s.constantize
#
#      reflection = parent_model.reflections[association.value.to_sym]
#      reflection_as = reflection.options[:as]
#
#      column = reflection.primary_key_name
#
#      # dot79 - populate criteria only if we found the field
#      if model.column_names.include?(column)
#        cond = " #{model.quoted_table_name}.#{model.connection.quote_column_name(column)} = :#{column} "
#        criteria[column.to_sym] = params[parent_id.key]
#
#        if (reflection_as)
#          key = "#{reflection_as}_type"
#          cond += " AND #{model.quoted_table_name}.#{model.connection.quote_column_name(key)} = :#{key} "
#          criteria[key.to_sym] = parent_model.to_s #class_name
#        end
#
#        # assume che :has_* :conditions => String || [String, (nil|Hash)]
#        conditions = reflection.options[:conditions]
#        conditions = [conditions] if conditions.is_a?(String)
#
#        cond += " AND #{conditions[0]} " if conditions.is_a?(Array) && conditions[0].is_a?(String) && (conditions[1].nil? || conditions[1].is_a?(Hash))
#        criteria.merge!(conditions[1]) if conditions.is_a?(Array) && conditions[1].is_a?(Hash)
#      end
#
#      order = reflection.options[:order]
#
#      return cond, criteria, order
#    end
#
#    #
#    # lookup for parent id; if found fill in a condition for finder method
#    #
#    def no_standard_lookup_for_parent_object
#      cond = nil
#      criteria = {}
#
#      params.each do |p|
#        if p[0].match(/.*_id$/)
#          begin
#            reflection = p[0].sub('_id', '').to_sym
#            cond = " #{model.reflections[reflection].options[:foreign_key] || model.reflections[reflection].primary_key_name}=:#{p[0]} "
#            criteria[eval(":#{p[0]}")] = p[1]
#          rescue
#            # there_is a foobar_id field but it's not a clear reflection
#            # let's see if it is a polymorphic association
#            cond, criteria = lookup_for_polymorphic_association(p) { |param_id|
#              cond = " #{ActiveRest::Helpers::Routes::Mapper::POLYMORPHIC[model.to_s][:foreign_type]}=:association_foreign_type AND #{ActiveRest::Helpers::Routes::Mapper::AS[param_id][:map_to_primary_key]}=:association_foreing_key "
#              criteria = {
#              :association_foreign_type => ActiveRest::Helpers::Routes::Mapper::AS[param_id][:map_to_model],
#              :association_foreing_key => p[1]
#              }
#              return cond, criteria, nil
#            }
#
#          end
#        end
#      end
#
#      return cond, criteria, nil
#    end

    #
    # try to detect polymorphic association upon current model
    # and information collected during bootstrap process in routes declaration
    #
#    def lookup_for_polymorphic_association(p)
#      if ActiveRest::Helpers::Routes::Mapper::POLYMORPHIC[model.to_s]
#        param_id = '%s_%s' % [ActiveRest::Helpers::Routes::Mapper::POLYMORPHIC[model.to_s][:reflection], p[0]]
#        if ActiveRest::Helpers::Routes::Mapper::AS.has_key?(param_id)
#          yield param_id if block_given?
#        else
#          return nil, {}
#        end
#      else
#        return nil, {}
#      end
#    end

    #
    # get pagination state from session
    #
    def load_pagination_state
      @pagination = session["#{model.to_s.pluralize.underscore}_pagination"] || {}
    end

    #
    # save pagination state to session
    #
    def save_pagination_state
      session["#{model.to_s.pluralize.underscore}_pagination"] = @pagination
    end
  end

end
end
