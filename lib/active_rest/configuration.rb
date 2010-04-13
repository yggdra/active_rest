#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# =
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: configuration.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest

  module Configuration

    DEFAULT_OPTIONS = {
      # cache mechanism
      :cache_path => File.join(RAILS_ROOT, 'tmp', 'cache', 'active_rest'),
      :x_sendfile => false,

      # pagination options
      :save_pagination => true,
      :default_pagination_offset => 0,
      :default_pagination_page_size => 100,

      # add to active_rest the capability to members with CRUD capability
      :members_crud => false,

      # how active rest must create routes
      :route_expand_model_namespace => false, # with false each association can point to different parent controller
    }.freeze

    def self.init
      @default_config = DEFAULT_OPTIONS.clone

      @config = load_config_file
      @config = (@config.nil? ? {} : @default_config.merge(@config))
    end

    def self.config
      @config
    end

    def self.[](k)
      @config[k]
    end

    def self.load_config_file
      file = File.expand_path(File.join(RAILS_ROOT, 'config', 'active_rest.yml'))
      conf = File.exists?(file) ? (YAML.load_file(file) || {}) : {}
      conf.symbolize_keys!
      conf[:plugins].symbolize_keys! if conf[:plugins]
      conf
    end

    def self.recursive_load(directory)
      root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
      Dir[File.join(root_dir, directory, '*.rb')].each { |ext| require ext }
    end

    def self.setup_plugins
      if ActiveRest::Configuration.config.has_key?(:plugins)
        if ActiveRest::Configuration.config[:plugins].has_key?(:others)
          ActiveRest::Configuration.config[:plugins][:others] = [ActiveRest::Configuration.config[:plugins][:others]] unless ActiveRest::Configuration.config[:plugins][:others].is_a?(Array)

          ActiveRest::Configuration.config[:plugins][:others].each do |plugin|
            require 'active_rest/plugins/others/'+plugin.to_s
          end
        end
      end
    end
  end

end
