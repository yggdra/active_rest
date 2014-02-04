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

module ActiveRest
module Controller

module Verbs

  #
  # Notes for overrinding methods in controller to handle more mime-types
  #
  # create / update must use the following syntax:
  #
  # def create
  #   super { |format, saved|
  #     if saved
  #       format.my_format { ... }
  #     else
  #       format.my_format { ... }
  #     end
  #   }
  #
  # on index do (where hfile is the handle to file to cache; automatic redirect built in in super):
  #
  # def index
  #  super { |format, hfile|
  #    if hfile
  #      format.my_format { hfile << ... }
  #    else
  #      format.my_format { ... }
  #    end
  #  }
  # end
  #
  # others:
  #
  # def show
  #   super { | format |
  #     format.my_format { ... }
  #   }
  # end
  #

  #
  # REST VERBS
  #A

  def schema
    @schema = ar_model.interfaces[:rest].schema

    respond_with(@schema.merge(:permissions => common_permissions))
  end

  def class_permissions
    respond_with(common_permissions)
  end

  def permissions
    respond_with(common_permissions)
  end

  def common_permissions
    intf = ar_model.interfaces[:rest]

    @user_capas = intf.init_capabilities(@aaa_context, @resource)

    res = {
      :allowed_actions => action_methods.select { |x| intf.action_allowed?(@user_capas, x) },
      :attributes => Hash[intf.attrs.map { |attrname, attr|
        [ attrname,
           (intf.attr_readable?(@user_capas, attr) ? 'R' : '') +
           (intf.attr_writable?(@user_capas, attr) ? 'W' : '') ]
      }],
    }
  end
  protected :common_permissions

  def index
#      @resources_relation = ar_model.all.includes(ar_model.interfaces[:rest].eager_loading_hints(:view => ar_view)) if ar_model

    begin
      ar_retrieve_resources
      ar_authorize_index_action
    rescue ActiveRest::Model::UnknownField => e
      raise Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'not found' ] },
              :retry_possible => false)
    end

    # Avoid responding with nil-classes when the array is empty
    root_name = ''

    if ar_model
      root_name = ActiveSupport::Inflector.pluralize(
                    ActiveSupport::Inflector.underscore(ar_model.name)).tr('/', '_')
    end

    respond_with(@resources,
                 :total => @resources_count,
                 :root => root_name) do |format|
      yield(format) if block_given?
    end
  end

  # GET /resource/1
  def show
    ar_retrieve_resource
    ar_authorize_action

    respond_with(@resource) do |format|
      yield(format) if block_given?
    end
  end

  # GET /resource/new
  def new
    @resource = ar_model.new

    respond_with(@resource) do |format|
      yield(format) if block_given?
    end
  end

  # POST /resources
# if parameter '_only_validation' is present only validation actions will be ran
  def create
    ar_authorize_model_action

    begin
      send(ar_transaction_handler) do
        before_create
        @resource ||= ar_model.ar_new(:rest, @request_resource, :aaa_context => @aaa_context)

        before_save

        @resource.save!
        after_create
      end
    rescue ActiveRest::Model::Interface::ResourceNotWritable => e
      raise Exception::Forbidden.new(e.message,
              :retry_possible => false)
    rescue ActiveRest::Model::Interface::AttributeNotWritable => e
      raise Exception::Conflict.new(e.message,
              :errors => { e.attribute_name => [ 'Is not writable' ] },
              :retry_possible => false)
    rescue ActiveRest::Model::Interface::AttributeNotFound => e
      raise Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'not found' ] },
              :retry_possible => false)
    rescue ActiveRecord::RecordInvalid => e
      raise Exception::UnprocessableEntity.new(e.message,
              :errors => @resource.errors.to_hash,
              :retry_possible => false)
    rescue ActiveRecord::RecordNotSaved => e
      raise Exception::UnprocessableEntity.new(e.message,
              :retry_possible => false)
    end

    after_create_commit

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => :created
    else
      ar_retrieve_resource(:id => @resource.id)
      respond_with(@resource, :status => :created) do |format|
        yield(format) if block_given?
      end
    end
  end

  # GET /resource/1/edit
  def edit
    ar_retrieve_resource
    ar_authorize_action

    respond_with(@resource) do |format|
      yield(format) if block_given?
    end
  end

  # PUT /resource/1
  # if parameter '_only_validation' is present only validation actions will be ran
  def update
    ar_retrieve_resource
    ar_authorize_action

    begin
      send(ar_transaction_handler) do
        before_update

        @resource.ar_apply_update_attributes(:rest, @request_resource, :aaa_context => @aaa_context)

        before_save

        @resource.save!

        after_update
      end
    rescue ActiveRest::Model::Interface::ResourceNotWritable => e
      raise Exception::Forbidden.new(e.message,
              :retry_possible => false)
    rescue ActiveRest::Model::Interface::AttributeNotWritable => e
      raise Exception::UnprocessableEntity.new(e.message,
              :errors => { e.attribute_name => [ 'Is not writable' ] },
              :retry_possible => false)
    rescue ActiveRest::Model::Interface::AttributeNotFound => e
      raise Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'not found' ] },
              :retry_possible => false)
    rescue ActiveRecord::RecordInvalid => e
      raise Exception::UnprocessableEntity.new(e.message,
              :errors => @resource.errors.to_hash,
              :retry_possible => false)
    rescue ActiveRecord::RecordNotSaved => e
      raise Exception::UnprocessableEntity.new(e.message,
              :retry_possible => false)
    end

    after_update_commit

    if is_true?(params[:_suppress_response])
      render :nothing => true
    else
      ar_retrieve_resource
      respond_with(@resource) do |format|
        yield(format) if block_given?
      end
    end
  end

  # DELETE /resource/1
  def destroy
    ar_retrieve_resource
    ar_authorize_action

    send(ar_transaction_handler) do
      before_destroy
      @resource.destroy
      after_destroy
    end

    after_destroy_commit

    respond_to do |format|
      yield(format) if block_given?
      format.xml { render :xml => {} }
      format.yaml { render :yaml => {} }
      format.json { render :json => {} }
      format.any { render :nothing => true }
    end
  end

  protected

  # Empty callbacks
  def before_save ; end

  def before_create ; end
  def after_create ; end
  def after_create_commit ; end

  def before_update ; end
  def after_update ; end
  def after_update_commit ; end

  def before_destroy ; end
  def after_destroy ; end
  def after_destroy_commit ; end
end

end
end
