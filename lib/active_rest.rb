#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# =
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: active_rest.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
end # eo module

require 'active_rest/routes' # route mapper

## MODELS annotations, overrides
require 'active_rest/models/annotations/attribute_annotations'
require 'active_rest/models/annotations/ordered_attributes'
#require 'active_rest/models/overrides'

## BASIC FEATURES
require 'active_rest/controller'

#require 'active_rest/controller/proxies'

