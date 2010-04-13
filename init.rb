#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# =
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: init.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#


# load up configuration
require 'active_rest/configuration'
#puts ActiveRest::Configuration.config.inspect

# MODELS annotations, overrides
ActiveRest::Configuration.recursive_load('active_rest/models/annotations')
ActiveRest::Configuration.recursive_load('active_rest/models/overrides')

# HELPERS routes, model, pagination
ActiveRest::Configuration.recursive_load('active_rest/helpers/routes')
ActiveRest::Configuration.recursive_load('active_rest/helpers/models')
ActiveRest::Configuration.recursive_load('active_rest/helpers/pagination');

# BASIC FEATURES
ActiveRest::Configuration.recursive_load('active_rest/controller')
ActiveRest::Configuration.recursive_load('active_rest/controller/actions')
ActiveRest::Configuration.recursive_load('active_rest/controller/proxies')

# starting point
ActiveRest::Configuration.init

require 'active_rest/routes' # route mapper
require 'active_rest/core' # rest_controller_for
