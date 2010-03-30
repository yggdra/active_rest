#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Helpers::Routes::RouteSet
#
# Author:: Angelo Grossini <angelo@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: route_set.rb 5105 2009-09-03 17:50:05Z dot79 $
#
# == Description
#
#
# This route_set.rb is used by Helpers.Pagination.Core
# ONLY with ActiveRest::Configuration.config[:stardard_controller_mapping] = true
#
# It helps to find the route to build the parent object relation
#

module ActiveRest
module Helpers
module Routes

  module RouteSet

    def self.included(base)
      base.class_eval do
        alias_method_chain :write_recognize_optimized!, :find_route
        alias_method_chain :remove_recognize_optimized!, :find_route
      end
    end

    private

    def write_recognize_optimized_with_find_route!

      tree = segment_tree(routes)
      body = generate_code(tree)

      remove_recognize_optimized!

      write_recognize_optimized_without_find_route!

      instance_eval %{
      def find_route(path, env)
        segments = to_plain_segments(path)
        index = #{body}
        return nil unless index
        while index < routes.size
          #puts index
          #puts routes[index].inspect
          result = routes[index].recognize(path, env) and return routes[index]
          index += 1
        end
        nil
      end
      }, '(route_set)', 1
    end

    def remove_recognize_optimized_with_find_route!
      remove_recognize_optimized_without_find_route!
      if respond_to?(:find_route)
        class << self
          remove_method :find_route
        end
      end
    end
  end

end
end
end

ActionController::Routing::RouteSet.send(:include, ActiveRest::Helpers::Routes::RouteSet)
