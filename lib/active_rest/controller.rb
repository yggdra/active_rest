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
module Controller

  include Finder
  include Rest # default verbs and actions
  include Validations # contains validation actions

  @config = OpenStruct.new(
    :cache_path => File.join(Rails.root, 'tmp', 'cache', 'active_rest'),
    :x_sendfile => false,
    :default_page_size => true,
    :members_crud => false,
    :route_expand_model_namespace => false
  )

  class << self
    attr_reader :config
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
    base.class_eval do
      class_inheritable_accessor :model
      class_inheritable_accessor :options
      class_inheritable_accessor :ar_xact_handler
      class_inheritable_accessor :attrs

      attr_accessor :target, :targets

      rescue_from ARException, :with => :arexception_rescue_action

      self.ar_xact_handler = :rest_default_transaction_handler

      # are we just requiring validations ?
      prepend_before_filter(:only => [ :update, :create ]) do
        # if the form contains a _only_validation field then RESTful request is considered a "dry-run" and gets rerouted to
        # a different action named validate_*

        if is_true?(params[:_only_validation])
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
        raise MethodNotAllowed.new('Read only in effect') if options[:read_only] && request.method != 'GET'

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

    base.extend(ClassMethods)
  end

  def rest_default_transaction_handler
    model.transaction do
      yield
    end
  end

  class Attribute < Model::Attribute
    attr_accessor :sub_attributes
    attr_accessor :klass

    def initialize(*args)
      super(*args)
      @sub_attributes = {}
    end

    def virtual(type, &block)
      raise 'Double defined attribute' if @type

      @type = type
      @source = block
    end

    def meta(val)
      @meta ||= {}
      @meta.merge!(val)
    end

    def attribute(name, &block)
      # TODO Check that attribute is embedded/nested

      @sub_attributes[name] ||= Attribute.new(self, name)
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
      self.attrs[name] ||= Attribute.new(self, name)
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

  private

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'yes', 'Y', 'YES', :true, :t].to_set
  def is_true?(val)
    TRUE_VALUES.include?(val)
  end

  #
  # generic rescue action. when html will handle a block
  #
  def arexception_rescue_action(e)

    message = "\nRendered exception: #{e.class} (#{e.message}):\n"
    message << "  " << clean_backtrace(e, :silent).join("\n  ")
    logger.warn("#{message}\n\n")

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => e.status
    else
      res = {
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

  def apply_sorting_to_relation(rel)
    if params[:sort]
      field = params[:sort].to_sym
      if !rel.table[field]
        raise BadRequest.new("Unknown field #{params[:sort]}")
      end

      dir = 'ASC'
      if params[:dir]
        dir = params[:dir].to_s.upcase
        raise BadRequest.new("Invalid sort direction #{dir}") unless %w(ASC DESC).include?(dir)
      end

      rel = rel.order(field + ' ' + dir)
    end

    rel
  end

  def apply_pagination_to_relation(rel)
    rel = rel.offset(params[:offset].to_i) if params[:start]
    rel = rel.limit(params[:limit].to_i) if params[:limit]
    rel
  end

  #
  # find all with conditions
  #
  def find_targets
    # prepare relations based on conditions

    finder_rel = apply_filter_to_relation(model.scoped)
    out_rel = apply_sorting_to_relation(finder_rel)
    out_rel = apply_pagination_to_relation(out_rel)

    @targets = out_rel.all
    @count = finder_rel.count
  end

  protected

  def clean_backtrace(exception, *args)
    defined?(Rails) && Rails.respond_to?(:backtrace_cleaner) ?
      Rails.backtrace_cleaner.clean(exception.backtrace, *args) :
      exception.backtrace
  end
end

end
