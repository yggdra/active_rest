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
  module Rest

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
      @targets_relation = model.scoped.includes(model.interfaces[:rest].eager_loading_hints(:view => rest_view))

      find_targets

      # Avoid responding with nil-classes when the array is empty
      root_name = ''

      if model
        root_name = ActiveSupport::Inflector.pluralize(
                      ActiveSupport::Inflector.underscore(model.name)).tr('/', '_')
      end

      respond_with(@targets.kind_of?(ActiveRecord::Relation) ? @targets.all : @targets,
                   :total => @count,
                   :root => root_name) do |format|
        yield(format) if block_given?
      end
    end

    # GET /target/1
    def show
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
        send(rest_transaction_handler) do
          before_create
          @target ||= model.new

          model.interfaces[:rest].apply_creation_attributes(@target, @request_resource)

          before_save

          @target.save!
          after_create
        end
      rescue ActiveRest::Model::Interface::AttributeNotWriteable => e
        raise ActiveRest::Exception::BadRequest.new(e.message,
                :per_field_msgs => { e.attribute_name => 'Is not writable' },
                :retry_possible => false)
      rescue ActiveRest::Model::Interface::AttributeNotFound => e
        raise ActiveRest::Exception::BadRequest.new(e.message,
                :per_field_msgs => { e.attribute_name => 'not found' },
                :retry_possible => false)
      rescue ActiveRecord::RecordInvalid => e
        raise ActiveRest::Exception::UnprocessableEntity.new(e.message,
                :per_field_msgs => target.errors.inject({}) { |h, (k, v)| h[k] = v; h },
                :retry_possible => false)
      rescue ActiveRecord::RecordNotSaved => e
        raise ActiveRest::Exception::UnprocessableEntity.new(e.message,
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
      respond_with(@target) do |format|
        yield(format) if block_given?
      end
    end

    # PUT /target/1
    # if parameter '_only_validation' is present only validation actions will be ran
    def update
      begin
        send(rest_transaction_handler) do
          before_update

          model.interfaces[:rest].apply_update_attributes(@target, @request_resource)

          before_save

          @target.save!

          after_update
        end
      rescue ActiveRest::Model::Interface::AttributeNotWriteable => e
        raise ActiveRest::Exception::BadRequest.new(e.message,
                :per_field_msgs => { e.attribute_name => 'Is not writable' },
                :retry_possible => false)
      rescue ActiveRest::Model::Interface::AttributeNotFound => e
        raise ActiveRest::Exception::BadRequest.new(e.message,
                :per_field_msgs => { e.attribute_name => 'not found' },
                :retry_possible => false)
      rescue ActiveRecord::RecordInvalid => e
        raise ActiveRest::Exception::UnprocessableEntity.new(e.message,
                :per_field_msgs => target.errors.inject({}) { |h, (k, v)| h[k] = v; h },
                :retry_possible => false)
      rescue ActiveRecord::RecordNotSaved => e
        raise ActiveRest::Exception::UnprocessableEntity.new(e.message,
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
      send(rest_transaction_handler) do
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

#    def x_sendfile
#      return if !ActiveRest::Controller.config.x_sendfile ||
#                @targets.length < 20
#
#      # DEFAULT
#      cache_file_name =  UUID.random_create.to_s
#      #cache_file_name = Digest::MD5.hexdigest(request.env['REMOTE_ADDR']+'_'+request.env['REQUEST_URI'])
#      #cache_file_name += '.'+params[:format] if params[:format]
#      cache_full_path_file_name = File.join(ActiveRest::Controller.config.cache_path, cache_file_name)
#
#      #unless File.exists?(cache_full_path_file_name)
#      f = File.new(cache_full_path_file_name,  'w+')
#      f << response.body
#      f.close
#
#      send_file cache_full_path_file_name,
#                :x_sendfile => true
#    end
  end

end
end
