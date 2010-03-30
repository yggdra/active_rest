#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

require File.dirname(__FILE__) + '/spec_helper'
root = File.expand_path(File.dirname(__FILE__))

Dir[File.join(root, 'controller_spec', '*.rb')].each { |ext| require ext }
