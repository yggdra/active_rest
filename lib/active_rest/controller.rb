#
# ActiveRest
#
# Copyright (C) 2008-2011, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

require 'ostruct'

module ActiveRest

# ActiveRest::Controller is a mixin to be included in your controllers to make them RESTful.
#
# If the model can be deducted from controller name, it is automatically configured, otherwise it has to be specified
# by calling {#rest_controller_for}
#
# Example:
#
# class User < ActiveRecord::Model
#   include ActiveRest::Model
# end
#
# class UsersController < ApplicationController
#   include ActiveRest::Controller
# end
#
# A RESTful controller provides several useful features:
#
# Standard REST verbs:
#
# GET /resources        => index
# GET /resources/schems => schema
# GET /resource/123     => show
# POST /resources       => create
# PUT /resources/123    => update
#
#
module Controller

  include Filters
  include Rest
  include Validations

  @config = OpenStruct.new(
    :cache_path => File.join(Rails.root, 'tmp', 'cache', 'active_rest'),
    :x_sendfile => false,
    :default_page_size => true,
  )

  class << self
    attr_reader :config
  end

  module ClassMethods

    def rest_controller_for(model, options = {})
      self.model = model
      self.rest_options = options
    end

    def rest_transaction_handler(method)
      self.rest_xact_handler = method
    end

    def view(name, &block)
      self.rest_views[name] ||= View.new(name)
      self.rest_views[name].instance_eval(&block)
      self.rest_views[name]
    end

    def filter(name, val)
      self.rest_filters[name] = val
    end

    def read_only!
      self.rest_read_only = true
    end

    private

    def map_column_type(type)
      case type
      when :datetime
        :timestamp
      else
        type
      end
    end
  end

  class ARException < StandardError
    attr_accessor :http_status_code
    attr_accessor :public_data
    attr_accessor :private_data

    def initialize(msg, status = :internal_server_error, public_data = {}, private_data = {})
      @http_status_code = status
      @public_data = public_data
      @private_data = private_data
      super msg

      # Avoid autofilling of additional_info
      @public_data[:additional_info] ||= ''
    end
  end

  class MethodNotAllowed < ARException
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :method_not_allowed, public_data, private_data
    end
  end

  class BadRequest < ARException
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :bad_request, public_data, private_data
    end
  end

  class NotFound < ARException
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :not_found, public_data, private_data
    end
  end

  class NotAcceptable < ARException
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :not_acceptable, public_data, private_data
    end
  end

  class UnprocessableEntity < ARException
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :unprocessable_entity, public_data, private_data
    end
  end

  def self.included(base)
    base.extend(ClassMethods)

    base.class_eval do
      class_inheritable_accessor :model
      class_inheritable_accessor :rest_options
      class_inheritable_accessor :rest_xact_handler
      class_inheritable_accessor :rest_views
      class_inheritable_accessor :rest_filters
      class_inheritable_accessor :rest_read_only

      attr_accessor :target, :targets

      rescue_from ARException, :with => :rest_ar_exception_rescue_action

      self.rest_xact_handler = :rest_default_transaction_handler

      # are we just requiring validations ?
      prepend_before_filter(:only => [ :update, :create ]) do

        if request.content_mime_type == :json
          @request_resource = ActiveSupport::JSON.decode(request.body)
        end

        # if a X-Validate-Only header is present RESTful request is considered a "dry-run" and gets rerouted to
        # a different action named validate_*

        if is_true?(request.headers['X-Validate-Only'])
          # I didn't find a better way to internal redirect to a different action
          new_action = 'validate_' + action_name
          action_name = new_action
          send(action_name)
          return false
        end

        true
      end

      prepend_before_filter do
        # prevent any action that can modify the record or change the table
        raise MethodNotAllowed.new('Read only in effect') if self.class.rest_read_only && request.method != 'GET'

        # setup I18n if options has this information
        I18n.locale = params[:language].to_sym if params[:language]

        true
      end

      # collection requests
      before_filter :only => [ :index ] do
        find_targets
        true
      end

      # member requests
      before_filter :only => [ :show, :edit, :update, :destroy, :validate_update ] do
        find_target
        true
      end

      base.append_after_filter :x_sendfile, :only => [ :index ]
    end

    base.rest_views = {}
    base.rest_filters = {}

    begin
      base.rest_controller_for(base.controller_name.classify.constantize)
    rescue NameError
    end
  end

  # Select the proper view based on URI parameters and action name.
  #
  # If no view is specified in URI parameter 'view' the action name is used.
  #
  # @return [View] the selected view
  #
  def rest_view
    if params[:view]
      self.class.rest_views[params[:view].to_sym]
    else
      self.class.rest_views[action_name.to_sym]
    end
  end

  protected

  # default transaction handler which simply starts an ActiveRecord transaction
  #
  def rest_default_transaction_handler
    model.transaction do
      yield
    end
  end

  private

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'yes', 'Y', 'YES', :true, :t].to_set
  def is_true?(val)
    TRUE_VALUES.include?(val)
  end

  # Rescue action for ARException kind of exceptions
  #
  def rest_ar_exception_rescue_action(e)

    message = "\nRendered exception: #{e.class} (#{e.message}):\n"
    message << "  " << clean_backtrace(e, :silent).join("\n  ")
    logger.warn("#{message}\n\n")

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => e.status
    else
      res = {
        :reason => :exception,
        :short_msg => e.message,
        :long_msg => '',
        :retry_possible => false,
        :additional_info => "Exception of class '#{e.class}'",
      }

      res.merge!(e.public_data) if e.respond_to?(:public_data)

      if request.local? || Rails.application.config.consider_all_requests_local
        res.merge!(e.private_data) if e.respond_to?(:private_data)

        res[:annotated_source_code] = e.annoted_source_code.to_s if e.respond_to?(:annoted_source_code)
        res[:application_backtrace] = clean_backtrace(e, :silent)
        res[:framework_backtrace] = clean_backtrace(e, :noise)
      end

      respond_to do |format|
        format.xml { render :xml => res, :status => e.http_status_code }
        format.yaml { render :yaml => res, :status => e.http_status_code }
        format.json { render :json => res, :status => e.http_status_code }
        yield(format, res, e.http_status_code) if block_given?
      end
    end
  end

  #
  # model name to underscore, even when namespaced
  #
  def model_symbol
    model.to_s.underscore.gsub(/\//, '_')
  end

  # find a single resource
  #
  def find_target(opts={})

    tid = opts[:id] || params[:id]
    opts.delete(:id)

    find_opts = {}

    @target = model.find(tid, find_opts)
  end

  def apply_sorting_to_relation(rel)
    if params[:sort]
      attr = rel.table[params[:sort].to_sym]
      raise BadRequest.new("Unknown field #{params[:sort]}") if !attr

      if params[:dir] && params[:dir].to_s.upcase == 'DESC'
        attr = attr.desc
      end

      rel = rel.order(attr)
    end

    rel
  end

  def apply_pagination_to_relation(rel)
    rel = rel.offset(params[:start].to_i) if params[:start]
    rel = rel.limit(params[:limit].to_i) if params[:limit]
    rel
  end

  # find all with conditions
  #
  def find_targets
    # prepare relations based on conditions

    rel = apply_json_filter_to_relation(model.scoped)
    rel = apply_simple_filter_to_relation(rel)
    rel = apply_search_to_relation(rel)
    rel = apply_sorting_to_relation(rel)
    out_rel = apply_pagination_to_relation(rel)

    @targets = out_rel.all
    @count = rel.count
  end

  protected

  def clean_backtrace(exception, *args)
    defined?(Rails) && Rails.respond_to?(:backtrace_cleaner) ?
      Rails.backtrace_cleaner.clean(exception.backtrace, *args) :
      exception.backtrace
  end
end

end
