
require 'action_controller/metal/renderers'

module ActionController::Renderers
  add :json do |obj, options|
    if self.class.include?(ActiveRest::Controller) && obj.respond_to?(:output)
      options[:with_perms] = true if is_true?(params[:_with_perms])
      json = obj.output(:rest, options.merge(:view => self.ar_view, :format => :json))
    elsif self.class.include?(ActiveRest::Controller) && obj.respond_to?(:ar_serializable_hash)
      options[:with_perms] = true if is_true?(params[:_with_perms])
      json = ActiveSupport::JSON.encode(obj.ar_serializable_hash(
               :rest, options.merge(:view => self.ar_view, :format => :json)))
    else
      json = obj.to_json(options) unless obj.kind_of?(String)
      json = "#{options[:callback]}(#{json})" unless options[:callback].blank?
    end

    self.content_type ||= Mime::JSON
    self.headers['X-Total-Resources-Count'] = options[:total].to_s if options[:total]
    json
  end
end

class ApplicationController < ActionController::Base
  protect_from_forgery

  respond_to :xml, :json
end
