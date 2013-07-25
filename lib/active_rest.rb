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

# Rails 3.1 - 3.2
module ActiveRecord::Associations::Builder
  class HasMany
    self.valid_options += [ :embedded ]
  end

  class HasOne
    self.valid_options += [ :embedded, :embedded_in ]
  end

  class BelongsTo
    self.valid_options += [ :embedded, :embedded_in ]
  end
end
