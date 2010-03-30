#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#

module ActiveRest
module Plugins
module Others

  module Dummy

    def self.included(base)
      puts 'OTHERS - DUMMY TEST!'
    end

  end

end
end
end

ActionController::Base.send(:include, ActiveRest::Plugins::Others::Dummy)
