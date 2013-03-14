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
require 'active_rest/controller/rest'
require 'active_rest/controller/validations'
require 'active_rest/controller/rescuer'

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
  include Rescuer

  attr_accessor :target
  attr_accessor :targets

  def self.included(base)
    base.extend(ClassMethods)

    base.instance_eval do
      class_attribute :model
      class_attribute :rest_options
      class_attribute :rest_views
      class_attribute :rest_scopes
      class_attribute :rest_read_only
      class_attribute :rest_transaction_handler

      define_callbacks :find_target
      define_callbacks :find_targets
    end

    base.rest_views = {}
    base.model = nil
    base.rest_options = {}
    base.rest_scopes = {}
    base.rest_transaction_handler = :rest_default_transaction_handler

    base.class_eval do
      class << self
        alias_method_chain :inherited, :ar
      end

      rescue_from ActiveRest::Exception, :with => :rest_ar_exception_rescue_action

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
        if self.class.rest_read_only && request.method != 'GET'
          raise ActiveRest::Exception::MethodNotAllowed.new('Read only in effect')
        end

        # setup I18n if options has this information
        I18n.locale = params[:language].to_sym if params[:language]

        true
      end

      # member requests
      before_filter :only => [ :show, :edit, :update, :destroy, :validate_update ] do
        @target_relation = model.scoped.includes(model.interfaces[:rest].eager_loading_hints(:view => rest_view)) if model
        find_target
        true
      end

#      base.append_after_filter :x_sendfile, :only => [ :index ]
    end

#    begin
#      base.rest_controller_for(base.controller_name.classify.constantize)
#    rescue NameError
#    end
  end

  module ClassMethods

    def inherited_with_ar(child)
      inherited_without_ar(child)

      child.rest_views = {}
      child.rest_scopes = {}
    end

    def rest_controller_without_model
    end

    def rest_controller_for(model, options = {})
      self.model = model
      self.rest_options = options
    end

    def view(name, &block)
      self.rest_views[name] ||= View.new(name)
      self.rest_views[name].instance_exec(&block) if block
      self.rest_views[name]
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
        self.rest_scopes[opts.keys.first] = opts.values.first
      elsif block
        self.rest_scopes[opts] = block
      else
        self.rest_scopes[opts] = opts.to_sym
      end
    end

    def read_only!
      self.rest_read_only = true
    end


    #
    # finder callbacks
    #
    def append_after_find_target_filter(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:find_target, :after, name, options)
      end
    end

    def prepend_after_find_target_filter(*names, &blk)
     _insert_callbacks(names, blk) do |name, options|
       set_callback(:find_target, :after, name, options.merge(:prepend => true))
     end
    end

    def skip_after_find_target_filter(*names, &blk)
     _insert_callbacks(names, blk) do |name, options|
       skip_callback(:find_target, :after, name, options)
     end
    end

    def append_after_find_targets_filter(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:find_targets, :after, name, options)
      end
    end

    def prepend_after_find_targets_filter(*names, &blk)
     _insert_callbacks(names, blk) do |name, options|
       set_callback(:find_targets, :after, name, options.merge(:prepend => true))
     end
    end

    def skip_after_find_targets_filter(*names, &blk)
     _insert_callbacks(names, blk) do |name, options|
       skip_callback(:find_targets, :after, name, options)
     end
    end

    alias_method :after_find_target, :append_after_find_target_filter
    alias_method :prepend_after_find_target, :prepend_after_find_target_filter
    alias_method :skip_after_find_target, :skip_after_find_target_filter

    alias_method :after_find_targets, :append_after_find_targets_filter
    alias_method :prepend_after_find_targets, :prepend_after_find_targets_filter
    alias_method :skip_after_find_targets, :skip_after_find_targets_filter

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

  # Select the proper view based on URI parameters and action name.
  #
  # If no view is specified in URI parameter 'view' the action name is used.
  #
  # @return [View] the selected view
  #
  def rest_view
    view = nil

    if params[:view]
      view = self.class.rest_views[params[:view].to_sym] ||
             self.class.model.interfaces[:rest].views[params[:view].to_sym]
    end

    view ||= self.class.rest_views[action_name.to_sym] ||
             self.class.model.interfaces[:rest].views[action_name.to_sym] ||
             View.new(:anonymous)
    view
  end

  def model
    @model || @model = self.class.model
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

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'yes', 'Y', 'YES', :true, :t]
  def is_true?(val)
    TRUE_VALUES.include?(val)
  end

  #
  # model name to underscore, even when namespaced
  #
  def model_symbol
    model.to_s.underscore.gsub(/\//, '_')
  end

  # find a single resource
  #
  def find_target(opts = {})
    run_callbacks :find_target, action_name do
      @target_relation ||= model.scoped

      tid = opts[:id] || params[:id]
      opts.delete(:id)

      find_opts = {}

      @target = @target_relation.find(tid, find_opts)
    end
  rescue ActiveRecord::RecordNotFound => e
    raise ActiveRest::Exception::NotFound.new(e.message,
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

    sorts.each do |sort|
      if sort =~ /^([-+]?)(.*)$/
        desc = ($1 && $1 == '-')
        attrname = $2

        (attr, rel) = rel.klass.nested_attribute(attrname, rel)
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
  def find_targets
    run_callbacks :find_targets, action_name do
      if params[:_search]
        # Fulltext search

        @targets = model.search(params[:_search])
        @count = @targets.count
      else
        @targets_relation ||= model.scoped

        # Filters
        @targets_relation = apply_scopes_to_relation(@targets_relation)
        @targets_relation = apply_json_filter_to_relation(@targets_relation)
        @targets_relation = apply_simple_filter_to_relation(@targets_relation)

        # Display filters
        @targets_relation = apply_sorting_to_relation(@targets_relation)
        @paginated_targets_relation = apply_pagination_to_relation(@targets_relation)

        @targets = @paginated_targets_relation
        @count = @targets_relation.count
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    raise ActiveRest::Exception::NotFound.new(e.message,
            :retry_possible => false)
  end
end

end
