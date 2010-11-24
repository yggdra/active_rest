#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Core
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>,
#          Angelo Grossini <angelo@intercom.it>
#
# License:: Proprietary
#
# Revision:: $Id: core.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

require 'ostruct'

module ActiveRest
module Controller

  include Finder
  include Pagination # manage pagination
  include Rest # default verbs and actions
  include MembersRest # default verbs and actions
  include Validations # contains validation actions

  @config = OpenStruct.new(
    :cache_path => File.join(Rails.root, 'tmp', 'cache', 'active_rest'),
    :x_sendfile => false,
    :save_pagination => true,
    :default_page_size => true,
    :members_crud => false,
    :route_expand_model_namespace => false
  )

  class << self
    attr_reader :config
  end

  class ARException < StandardError
    attr_accessor :status
    attr_accessor :data

    def initialize(msg, status = :internal_server_error, data = {})
      @data = data
      @status = status
      super msg
    end

    # to_hash will be used by to_json
    def to_hash
     {
      :short_msg => self.message,
     }.merge(@data)
    end
  end

  class MethodNotAllowed < ARException
    def initialize(msg = '', data = {})
      super msg, :method_not_allowed, data
    end
  end

  class BadRequest < ARException
    def initialize(msg = '', data = {})
      super msg, :bad_request
    end
  end

  class NotFound < ARException
    def initialize(msg = '', data = {})
      super msg, :not_found
    end
  end

  class NotAcceptable < ARException
    def initialize(msg = '', data = {})
      super msg, :not_acceptable
    end
  end

  class UnprocessableEntity < ARException
    def initialize(msg = '', data = {})
      super msg, :unprocessable_entity, data
    end
  end

  def self.included(base)
    base.class_eval do
      class_inheritable_accessor :model
      class_inheritable_accessor :options
      class_inheritable_accessor :ar_xact_handler
      class_inheritable_accessor :attrs

      attr_accessor :target, :targets

      self.ar_xact_handler = :rest_default_transaction_handler

#      build_associations_proxies

      # if read only not allow these actions
      prepend_before_filter :check_validation_action, :only => [ :update, :create ] # are we just requiring validations ?
      prepend_before_filter :check_read_only

      before_filter :prepare_i18n
      before_filter :find_target, :only => [ :show, :edit, :update, :destroy, :validate_update ] # 1 resource?
      before_filter :find_targets, :only => [ :index ] # find all resources ?
      before_filter :prepare_schema, :only => :schema

      base.append_after_filter :x_sendfile, :only => [ :index ]

      rescue_from ARException, :with => :generic_rescue_action
    end

    base.extend(ClassMethods)
  end

  def rest_default_transaction_handler
    model.transaction do
      yield
    end
  end

  class Attribute < Model::Attribute
    attr_accessor :sub_attributes

    def initialize(*args)
      super(*args)
      @sub_attributes = {}
    end

    def virtual(type, &block)

      raise 'Double defined attribute' if @type

      @type = type
      @source = block
    end

    def attribute(name, &block)
      # TODO Check that attribute is embedded/nested

      @sub_attributes[name] ||= Attribute.new(name)
      @sub_attributes[name].instance_eval(&block)
      @sub_attributes[name]
    end

    def definition
      res = super

      if !sub_attributes.empty?
        res[:members_schema] ||= {}
        sub_attributes.each do |k,v|
          res[:members_schema][:attrs] ||= {}
          res[:members_schema][:attrs][k] = v.definition
        end
      end

      res
    end
  end

  module ClassMethods

    def rest_transaction_handler(method)
      self.ar_xact_handler = method
    end

    def rest_controller_for(model, options = {})
      self.model = model
      self.options = options
      self.attrs = {}
    end

    def rest_controller(options = {})
      rest_controller_for(self.controller_name.classify.constantize, options)
    end

    def attribute(name, &block)
      self.attrs[name] ||= Attribute.new(name)
      self.attrs[name].instance_eval(&block)
      self.attrs[name]
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

  #
  # in your controller you can override these methods this way:
  #
  # def verify_authenticity_token
  #   super { |f|
  #     f.format_one { render ... }
  #     f.format_two { render ... }
  #   }
  # end
  #

  protected

  #
  # handle authenticity token (html in primis)
  #
#  def verify_authenticity_token(&blk)
#    respond_to do | format |
#      format.html { super }
#      format.xml {}
#      format.json {}
#      format.jsone {}
#      format.yaml {}
#      blk.call(format) if blk # overriding to handle other format
#      format.any { super } # unhandled format? do authenticity token!
#    end
#  end

  #
  # setup I18n if options has this information
  #
  def prepare_i18n
    I18n.locale = params[:language].to_sym if params[:language]
  end

  private

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'yes', 'Y', 'YES', :true, :t].to_set
  def is_true?(val)
    TRUE_VALUES.include?(val)
  end

  #
  # generic rescue action. when html will handle a block
  #
  def generic_rescue_action(e)

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => e.status
    else
      respond_to do |format|
        format.xml { render :xml => e.to_hash, :status => e.status }
        format.yaml { render :text => e.to_hash, :status => e.status }
        format.json { render :json => e.to_hash, :status => e.status }
        yield(format) if block_given?
      end
    end
  end
  alias ar_generic_rescue_action generic_rescue_action


  #
  # model name to underscore, even when namespaced
  #
  def model_symbol
    model.to_s.underscore.gsub(/\//, '_')
  end

  #
  # find a single resource; return object or, if action is not include
  # into a object ruleset, return an hash
  #
  def find_target(options={})
#    joins, select = build_joins

    tid = options[:id] || params[:id]
    options.delete(:id)

    find_options = {}
#    find_options[:select] = select unless select.blank?
#    find_options[:joins] = joins unless joins.blank?
    @target = model.find(tid, find_options)
  end

  #
  # find all with conditions
  #
  def find_targets

    # Update our pagination state from params[] and session if persistant
    update_pagination_state

    # prepare relations based on conditions

    finder_rel = build_finder_relation
    pagination_rel = build_pagination_relation

    @targets = (finder_rel & pagination_rel).all
    @count = finder_rel.count
  end

  def prepare_schema
    @schema = model.schema(:additional_attrs => self.attrs)
  end

  #
  # avoid any action that can modify the record or change the table
  #
  def check_read_only
    raise MethodNotAllowed if options[:read_only] && request.method != 'GET'
  end


end

end
