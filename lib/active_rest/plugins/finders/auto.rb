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
# Revision:: $Id: auto_discover.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Plugins
module Finders

  module Auto

    protected

    def self.registry_filters
      return []
    end

    #
    # This class queries the plugin registry and try to find out the best plugin
    # matching the most of the incoming parameters
    #

    def self.build_conditions(target_model, params, options={})
      finders = []

      # assign points to each plugin
      ActiveRest::FindersRegistry.registry.keys.each do |finder|
        filter_points = 0

        params.keys.each do |p|
          filter_points += 1 if ActiveRest::FindersRegistry.registry[finder].include?(p.to_s)
        end

        finders << { :finder => finder, :points => filter_points, :module => eval("ActiveRest::Plugins::Finders::#{finder.to_s.capitalize}") }
      end

      # find the best one
      best_one = { :finder => nil, :points => 0, :module => nil }
      finders.each do |f|
        best_one = f if (f[:points] > best_one[:points])
      end

      if best_one[:finder] == nil
        parent = {}

        unless options[:condition_parent].blank?
          parent[:conditions] = []
          parent[:conditions] << options[:condition_parent]
          parent[:conditions] << options[:criteria_parent] unless options[:criteria_parent].blank?
        end

        parent[:order] = options[:order_parent] unless options[:order_parent].blank?

        return parent
      end

      # return the best finder builder
      return best_one[:module].build_conditions(target_model, params, options)
    end

  end
end
end
end
