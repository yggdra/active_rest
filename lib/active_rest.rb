require "active_rest/version"

require 'active_rest/routes'
require 'active_rest/model'
require 'active_rest/view'
require 'active_rest/controller'

require 'active_record/associations/builder/has_many'

require 'active_record'

module ActiveRest
class Engine < Rails::Engine
end
end

module ActiveRecord::Associations::Builder
  class HasMany
    alias_method :ar_valid_options, :valid_options
    def valid_options
      ar_valid_options + [ :embedded ]
    end
  end

  class HasOne
    alias_method :ar_valid_options, :valid_options
    def valid_options
      ar_valid_options + [ :embedded, :embedded_in ]
    end
  end

  class BelongsTo
    alias_method :ar_valid_options, :valid_options
    def valid_options
      ar_valid_options + [ :embedded, :embedded_in ]
    end
  end
end
