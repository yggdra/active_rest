#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::FindersRegistry
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: finders_registry.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest

  module FindersRegistry

    def self.init
      @registry = {}
      finder_dir = 'active_rest/plugins/finders'
      root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
      Dir[File.join(root_dir, finder_dir, '*.rb')].each do |fnd|
        require fnd
        fnd_name = File.basename(fnd, '.rb')
        #puts "Loading finder #{fnd_name.inspect} -- #{eval("ActiveRest::Plugins::Finders::#{fnd_name.to_s.capitalize}.registry_filters").inspect} "

        self.registry_pluging(fnd_name, eval("ActiveRest::Plugins::Finders::#{fnd_name.to_s.capitalize}.registry_filters"))
      end

      #puts @registry.inspect
    end

    def self.registry_pluging(plugin, options)
      @registry[plugin.to_sym] = options
    end

    def self.registry
      @registry
    end

    def self.[](k)
      @registry[k]
    end
  end
end
