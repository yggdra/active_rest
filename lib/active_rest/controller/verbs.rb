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
    @schema = model.interfaces[:rest].schema

    respond_to do |format|
      format.xml { render :xml => @schema.to_xml(:dasherize => false) }
      format.yaml { render :text => @schema }
      format.json { render :json => @schema }
      yield(format) if block_given?
    end
  end

  def index
#      @targets_relation = model.all.includes(model.interfaces[:rest].eager_loading_hints(:view => ar_view)) if model

    begin
      find_targets
    rescue ActiveRest::Model::UnknownField => e
      raise ActiveRest::Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'not found' ] },
              :retry_possible => false)
    end

    # Avoid responding with nil-classes when the array is empty
    root_name = ''

    if model
      root_name = ActiveSupport::Inflector.pluralize(
                    ActiveSupport::Inflector.underscore(model.name)).tr('/', '_')
    end

    respond_with(@targets,
                 :total => @count,
                 :root => root_name) do |format|
      yield(format) if block_given?
    end
  end

  # GET /target/1
  def show
    find_target

    ar_check_whole_verb_authorization(:show)

    respond_with(@target) do |format|
      yield(format) if block_given?
    end
  end

  # GET /target/new
  def new
    @target = model.new

    respond_with(@target) do |format|
      yield(format) if block_given?
    end
  end

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

  # POST /targets
# if parameter '_only_validation' is present only validation actions will be ran
  def create
    begin
      send(ar_transaction_handler) do
        before_create
        @target ||= model.new

        model.interfaces[:rest].apply_creation_attributes(@target, @request_resource, :aaa_context => @aaa_context)

        before_save

        @target.save!
        after_create
      end
    rescue ActiveRest::Model::Interface::AttributeNotWriteable => e
      raise Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'Is not writable' ] },
              :retry_possible => false)
    rescue ActiveRest::Model::Interface::AttributeNotFound => e
      raise Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'not found' ] },
              :retry_possible => false)
    rescue ActiveRecord::RecordInvalid => e
      raise Exception::UnprocessableEntity.new(e.message,
              :errors => target.errors.to_hash,
              :retry_possible => false)
    rescue ActiveRecord::RecordNotSaved => e
      raise Exception::UnprocessableEntity.new(e.message,
              :retry_possible => false)
    end

    after_create_commit

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => :created
    else
      find_target(:id => @target.id)
      respond_with(@target, :status => :created) do |format|
        yield(format) if block_given?
      end
    end
  end

  # GET /target/1/edit
  def edit
    find_target

    respond_with(@target) do |format|
      yield(format) if block_given?
    end
  end

  # PUT /target/1
  # if parameter '_only_validation' is present only validation actions will be ran
  def update
    find_target

    begin
      send(ar_transaction_handler) do
        before_update

        @target.ar_apply_update_attributes(:rest, @request_resource, :aaa_context => @aaa_context)

        before_save

        @target.save!

        after_update
      end
    rescue ActiveRest::Model::Interface::AttributeNotWriteable => e
      raise Exception::UnprocessableEntity.new(e.message,
              :errors => { e.attribute_name => [ 'Is not writable' ] },
              :retry_possible => false)
    rescue ActiveRest::Model::Interface::AttributeNotFound => e
      raise Exception::BadRequest.new(e.message,
              :errors => { e.attribute_name => [ 'not found' ] },
              :retry_possible => false)
    rescue ActiveRecord::RecordInvalid => e
      raise Exception::UnprocessableEntity.new(e.message,
              :errors => target.errors.to_hash,
              :retry_possible => false)
    rescue ActiveRecord::RecordNotSaved => e
      raise Exception::UnprocessableEntity.new(e.message,
              :retry_possible => false)
    end

    after_update_commit

    if is_true?(params[:_suppress_response])
      render :nothing => true
    else
      find_target
      respond_with(@target) do |format|
        yield(format) if block_given?
      end
    end
  end

  # DELETE /target/1
  def destroy
    find_target

    send(ar_transaction_handler) do
      before_destroy
      @target.destroy
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

  def ar_check_whole_verb_authorization(verb)
    @ar_authorized = nil

    run_callbacks verb

    if !@ar_authorized
      raise Exception::AuthorizationError.new(
            :reason => :forbidden,
            :short_msg => 'You are not authorized to access the resource.')
    end
  end

end

end
end
