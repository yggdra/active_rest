
require 'action_controller/metal/renderers'

ActionController.add_renderer :json do |json, options|
  unless json.respond_to?(:to_str)
    opts = {}

    if self.class.include?(ActiveRest::Controller)
      opts.merge! :view => self.rest_view
    end

    json = ActiveSupport::JSON.encode(json, opts)
  end

  json = "#{options[:callback]}(#{json})" unless options[:callback].blank?
  self.content_type ||= Mime::JSON

  json
end

class ApplicationController < ActionController::Base
  protect_from_forgery

  respond_to :html, :xml, :json
end
