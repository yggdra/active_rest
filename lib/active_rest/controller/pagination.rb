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
  # this module handles conditions, sorting and paginations decoding the incoming json (it describes the filters),
  # then store in session the parameters used to run the query
  #
  module Pagination

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
