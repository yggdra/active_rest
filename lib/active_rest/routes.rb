#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# =
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: routes.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

#
# install ActiveRest routes
#
# config/routes.rb
# ----------------
#  ActionController::Routing::Routes.draw do |map|
#
#    map.active :resource, :model => Model
#
#   OR
#
#   map.namaspace :myns do | ns|
#     ns.active  :resource, :model => Model
#   end
#


#module ActiveRest
#
#  module Routes
#
#    #
#    # map an active_rest resource
#    #
#    def active(controller, params={}, &block)
#      map = self
#
#      raise ArgumentError, 'missing model' unless params.has_key?(:model)
#
#      # add to inflector non standard singulars and plurals
#      if params[:plural] || params[:singular]
#        plural = params[:plural]
#        singular = params[:singular]
#        singular = controller if plural && !singular
#        plural = controller if singular && !plural
#        ActiveSupport::Inflector.inflections.irregular(singular.to_s, plural.to_s)
#      end
#
#      options = ActiveRest::Helpers::Routes::Mapper.merge(params)
#
#      # do we have to manage a single resource?
#      if params[:single_resource]
#        map.resource controller, options
#      else
#        if ActiveRest::Configuration.config[:route_expand_model_namespace]
#          options[:controller] = params[:model].to_s.tableize.gsub(/\//, '_')
#        end
#
#        map.resources controller, options if options[:has_many].blank?
#
#        unless options[:has_many].blank?
#          hm = options.delete(:has_many)
#
#          map.resources controller, options do | route |
#            block.call route if block_given?
#
#            hm.each do | subroute, klass |
#              controller_name = klass.to_s.tableize
#
#              if ActiveRest::Configuration.config[:route_expand_model_namespace]
#                controller_name = controller_name.gsub(/\//, '_')
#              else
#                controller_name = klass.to_s.demodulize.tableize
#              end
#
#              route.resources subroute.to_sym, :controller => controller_name
#            end
#          end
#        end
#      end
#
#      r  = ActionController::Resources::Resource.new(controller, ActiveRest::Helpers::Routes::Mapper.merge(params))
#
#      # add this controller to ROUTES mapper ??
#      if (params[:act_as_plain_rest].nil?) or (params[:act_as_plain_rest]==false)
#        ActiveRest::Helpers::Routes::Mapper::ROUTES[controller] =
#             { :path_prefix => r.path_prefix, :url => "/#{r.options[:namespace]}#{r.plural.to_s}", :resource => r }
#      end
#    end
#  end
#
#end

module ::ActionController #:nodoc:
  module Routing #:nodoc:
    class Mapper #:nodoc:
      module Resources
#        include ActiveRest::Routes
        def aresources(*resources, &block)
          resources(*resources) do
            collection do
              get :schema
            end

            yield if block_given?
          end
        end
      end
    end
  end
end
