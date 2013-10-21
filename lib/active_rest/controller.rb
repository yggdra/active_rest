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

require 'active_rest/controller/filters'
require 'active_rest/controller/verbs'
require 'active_rest/controller/validations'
require 'active_rest/controller/rescuer'
require 'active_rest/controller/exceptions'

module ActiveRest

# ActiveRest::Controller is a mixin to be included in your controllers to make them RESTful.
#
# If the model can be deducted from controller name, it is automatically configured, otherwise it has to be specified
# by calling {#ar_controller_for}
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
  extend ActiveSupport::Concern

  include Filters
  include Verbs
  include Validations
  include Rescuer

  protected

  attr_accessor :resource
  attr_accessor :resources

  included do
    class_attribute :ar_model
    self.ar_model = nil
    protected :ar_model, :ar_model=, :ar_model?

    class_attribute :ar_options
    self.ar_options = {}
    protected :ar_options, :ar_options=, :ar_options?

    class_attribute :ar_views
    self.ar_views = {}
    protected :ar_views, :ar_views=, :ar_views?

    class_attribute :ar_scopes
    self.ar_scopes = {}
    protected :ar_scopes, :ar_scopes=, :ar_scopes?

    class_attribute :ar_read_only
    self.ar_read_only = false
    protected :ar_read_only, :ar_read_only=, :ar_read_only?

    class_attribute :ar_transaction_handler
    self.ar_transaction_handler = :ar_default_transaction_handler
    protected :ar_transaction_handler, :ar_transaction_handler=, :ar_transaction_handler?

    define_callbacks :ar_retrieve_resource
    protected :_ar_retrieve_resource_callbacks, :_ar_retrieve_resource_callbacks=, :_ar_retrieve_resource_callbacks?

    define_callbacks :ar_retrieve_resources
    protected :_ar_retrieve_resources_callbacks, :_ar_retrieve_resources_callbacks=, :_ar_retrieve_resources_callbacks?

    class << self
      alias_method_chain :inherited, :ar
    end

    rescue_from Exception do |e|
      ar_exception_rescue_action(e)
    end

    rescue_from Exception::AAAError do |e|
      ar_exception_rescue_action(e, :log_level => :none)
    end

    # are we just requiring validations ?
    prepend_before_action(:only => [ :update, :create ]) do
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

    prepend_before_action do
      # prevent any action that can modify the record or change the table
      if self.class.ar_read_only && request.method != 'GET'
        raise Exception::MethodNotAllowed.new('Read only in effect')
      end

      true
    end

#    begin
#      base.ar_controller_for(base.controller_name.classify.constantize)
#    rescue NameError
#    end
  end

  # Select the proper view based on URI parameters and action name.
  #
  # If no view is specified in URI parameter 'view' the action name is used.
  #
  # @return [View] the selected view
  #
  def ar_view
    view = nil

    if params[:view]
      view = self.class.ar_views[params[:view].to_sym] ||
             self.class.ar_model.interfaces[:rest].views[params[:view].to_sym]
    end

    view ||= self.class.ar_views[action_name.to_sym] ||
             self.class.ar_model.interfaces[:rest].views[action_name.to_sym] ||
             View.new(:anonymous)
    view
  end

  def ar_model
    @ar_model || @ar_model = self.class.ar_model
  end

  # default transaction handler which simply starts an ActiveRecord transaction
  #
  def ar_default_transaction_handler
    ar_model.transaction do
      yield
    end
  end

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'yes', 'Y', 'YES', :true, :t]
  def is_true?(val)
    TRUE_VALUES.include?(val)
  end

  #
  # model name to underscore, even when namespaced
  #
  def ar_model_symbol
    ar_model.to_s.underscore.gsub(/\//, '_')
  end

  # find a single resource
  #
  def ar_retrieve_resource(opts = {})
    @resource_relation ||= ar_model
    @resource_relation = ar_model.includes(ar_model.interfaces[:rest].eager_loading_hints(:view => ar_view)) if ar_model

    run_callbacks :ar_retrieve_resource do
      tid = opts[:id] || params[:id]
      opts.delete(:id)

      @resource = @resource_relation.find(tid)
    end

    #ar_authorize_action if !opts[:skip_authorization]

    @resource
  rescue ActiveRecord::RecordNotFound => e
    raise Exception::NotFound.new(e.message,
            :retry_possible => false)
  end

  # Add conditions to a relation to implement sorting. Conditions are obtained from controller's parameters
  #
  # If parameter :sort is specified then an .order statement is applied to the relation for each column
  # whose name is specified in a comma-separated list.
  #
  # column name may be prepended by '-' or '+' to indicate descending or ascending order. By default ascending order is used.
  #
  # E,g.:
  #
  # sort=+name,-prodiry,id
  #
  # @return [ActiveRecord::Relation] the new relation
  #
  def apply_sorting_to_relation(rel)
    return rel if !params[:sort]

    sorts = params[:sort].split(',')

    sorts.reverse.each do |sort|
      if sort =~ /^([-+]?)(.*)$/
        desc = ($1 && $1 == '-')
        attrname = $2

        (attr, path) = rel.nested_attribute(attrname)

        rel = rel.joins { path[1..-1].inject(self.__send__(path[0]).outer) { |a,x| a.__send__(x).outer } } if path.any?

        attr = attr.desc if desc

        rel = rel.order(attr)
      end
    end

    rel
  end

  # Add conditions to a relation to implement pagination. Conditions are obtained from controller's parameters
  #
  # If parameter :start is specified then an .offset statement is applied to the relation
  # If parameter :limit is specified then a .limit statement is applied to the relation
  #
  # @return [ActiveRecord::Relation] the new relation
  #
  def apply_pagination_to_relation(rel)
    rel = rel.offset(params[:start].to_i) if params[:start]
    rel = rel.limit(params[:limit].to_i) if params[:limit]
    rel
  end

  # find all with conditions
  #
  def ar_retrieve_resources
    run_callbacks :ar_retrieve_resources do
      if params[:_search]
        # Fulltext search

        @resources = ar_model.search(params[:_search])
        @resources_count = @resources.count
      else
        @resources_relation ||= ar_model.all

        # Filters
        @resources_relation = apply_scopes_to_relation(@resources_relation)
        @resources_relation = apply_json_filter_to_relation(@resources_relation)
        @resources_relation = apply_simple_filter_to_relation(@resources_relation)

        # Display filters
        @resources_relation = apply_sorting_to_relation(@resources_relation)
        @paginated_resources_relation = apply_pagination_to_relation(@resources_relation)

        @resources = @paginated_resources_relation
        @resources_count = @resources_relation.count
      end
    end

    @resources
  rescue ActiveRecord::RecordNotFound => e
    raise Exception::NotFound.new(e.message,
            :retry_possible => false)
  end

  def ar_authorize_model_action(opts = {})
    ar_authorize_action(opts)
  end

  def ar_authorize_index_action(opts = {})
    opts[:action] ||= params[:action].to_sym

    intf = ar_model.interfaces[:rest]

    return true if !intf.authorization_required?

    @user_capas = intf.init_capabilities(@aaa_context)

    if !@user_capas.any? && !@resources.any?
      raise Exception::AuthorizationError.new(
            :reason => :forbidden,
            :short_msg => 'You do not have the required capability to access the resources.')
    end

    true
  end

  def ar_authorize_action(opts = {})
    opts[:action] ||= params[:action].to_sym

    intf = ar_model.interfaces[:rest]

    return true if !intf.authorization_required?

    @user_capas = intf.init_capabilities(@aaa_context, @resource)

    if !@user_capas.any?
      raise Exception::AuthorizationError.new(
            :reason => :forbidden,
            :short_msg => 'You do not have the required capability to access the resource.')
    end

    unless intf.action_allowed?(@user_capas, opts[:action])
      raise Exception::AuthorizationError.new(
            :reason => :forbidden,
            :short_msg => 'You do not have the required capability to operate this action.')
    end

    true
  end

  module ClassMethods
    def inherited_with_ar(child)
      inherited_without_ar(child)

      child.ar_views = {}
      child.ar_scopes = {}
    end

    def ar_controller_without_model
    end

    def ar_controller_for(ar_model, options = {})
      self.ar_model = ar_model
      self.ar_options = options
    end

    def view(name, &block)
      self.ar_views[name] ||= View.new(name)
      self.ar_views[name].instance_exec(&block) if block
      self.ar_views[name]
    end

    # Define a scope available to be selected with the :scopes parameter.
    # The scope itself can be a scope defined in the model or a block operating on the relation.
    #
    # If opts is a symbol the scope named as the scope is selected.
    # If opts is a hash of a single element, the name will be the key and the scope the value.
    # If opts is a symbol and a block is passed the block will be invoked with the relation as a parameter and should
    # return a relation with constraints applied. The block is called with the controller's bindings so it can
    # access params and such.
    #
    # Examples:
    #
    # scope :name
    # scope :name => :scopename
    # scope(:name) { |rel| rel.where(...) }
    #
    def scope(opts, &block)
      if opts.is_a?(Hash)
        self.ar_scopes[opts.keys.first] = opts.values.first
      elsif block
        self.ar_scopes[opts] = block
      else
        self.ar_scopes[opts] = opts.to_sym
      end
    end

    def read_only!
      self.ar_read_only = true
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

end

end
