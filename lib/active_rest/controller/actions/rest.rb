#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Actions::Rest
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: rest.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#


module ActiveRest
module Controller
module Actions

  module Rest

    def self.included(base)
      #:nodoc:
      base.append_after_filter :x_sendfile, :only => [ :index ]
    end

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
    #

    # can be called with the following parameters:
    # - no_cache: any number will trigger the response cache mechanism
    #
    def index(&blk)
      respond_to do |format|
        format.html
        format.xml { render :xml => @targets.to_xml(:root => target_model_to_underscore) }
        format.yaml { render :text => @targets.to_yaml }
        format.json { render :json => @targets }
        format.jsone { render :json => { target_model_to_underscore => @targets, :total => @count, :success => true } }
        blk.call(format, nil) if blk
      end
    end

    # GET /target/1
    def show(&blk)
      respond_to do |format|
        format.html
        format.xml { render :xml => target.to_xml(:root => target_model_to_underscore) } ## see above note
        format.yaml { render :text => target.to_yaml }
        format.json { render :json => target }
        format.jsone {
          root = extjs_options[:standard_crud] ? target_model_to_underscore : :data
          render :json => { :ns => target_model_to_underscore, root => target, :success => true }
        }
        blk.call(format) if blk
      end
    end

    # GET /target/new
    def new(&blk)
      @target = target_model.new
      respond_to do | format |
        format.html
        format.xml { render :xml => @target.to_xml(:root => target_model_to_underscore) } ## see above note
        format.yaml { render :text => @target.to_yaml }
        format.json { render :json => @target.to_json }
        format.jsone { render :json => @target.to_json }
        blk.call(format) if blk
      end
    end


    # POST /targets
    # if parameter '_only_validation' is present only validation actions will be runned;
    # see ActiveRest::Controller::Actions::Validations
    def create(&blk)
      saved = false

      begin
        target_model.transaction do
          guard_protected_attributes = self.respond_to?(:guard_protected_attributes) ? send(:guard_protected_attributes) : true
          @target = target_model.new
          @target.send(:attributes=, params[target_model_to_underscore], guard_protected_attributes)
          saved = @target.save!
        end
      rescue ActiveRecord::RecordInvalid
        # don't do anything, let the controller respond
      end

      if params[:_suppress_response]
        render :nothing => true, :status => status
      else
        if saved
          find_target(:id => @target.id)
          write_action_successful_response(:created)
        else
          write_action_error_response
        end
      end
    rescue Exception => ex
      require 'pp'
      Rails.logger.error ex.pretty_inspect
      Rails.logger.error ex.backtrace.pretty_inspect
      generic_rescue_action(:bad_request) # something nasty has happend
    end

    # GET /target/1/edit
    def edit(&blk)
      respond_to do |format|
        format.html
        format.xml { render :xml => target.to_xml(:root => target_model_to_underscore) } ## see above note
        format.yaml { render :text => target.to_yaml }
        format.json { render :json => target.to_json }
        format.jsone { render :json => { :ns => target_model_to_underscore, :data => target.to_json, :success => true } }
        blk.call(format)
      end
    end

    # PUT /target/1
    # if parameter '_only_validation' is present only validation actions will be runned;
    # see ActiveRest::Controller::Actions::Validations
    def update(&blk)
      saved = false
      begin
        target_model.transaction do
          guard_protected_attributes = self.respond_to?(:guard_protected_attributes) ? send(:guard_protected_attributes) : true
          @target.send(:attributes=, params[target_model_to_underscore], guard_protected_attributes)
          saved = @target.save!
        end
      rescue ActiveRecord::RecordInvalid => ex
        # don't do nothing, let the controller respond
      end

      if params[:_suppress_response]
        render :nothing => true, :status => status
      else
        if saved
          find_target
          write_action_successful_response(:accepted)
        else
          write_action_error_response
        end
      end

    rescue Exception => ex
      require 'pp'
      Rails.logger.error ex.pretty_inspect
      Rails.logger.error ex.backtrace.pretty_inspect
      generic_rescue_action(:bad_request) # something nasty has happend
    end


    # DELETE /target/1
    def destroy(&blk)
      @target.destroy

      respond_to do |format|
        format.html {
          flash[:notice] = '#{target_model.to_s.underscore} was successfully destroyed.'
          redirect_to :action => :index
        }

        # 200 - Ok
        format.xml { head :status => :ok }
        format.yaml { head :status => :ok }
        format.json { head :status => :ok }
        format.jsone { render :json => { :success => true }, :status => :ok }
        blk.call(format) if blk
      end
    end

    protected

    def write_action_successful_response(status)
      respond_to do |format|

        format.html {
          flash[:notice] = 'Operation successful.'
          redirect_to :action => :index
        }

        # 202 Accepted
        format.xml { render :xml => @target.to_xml(:root => target_model_to_underscore), :status => status }
        format.yaml { render :text => @target.to_yaml, :status => status }
        format.json { render :json => @target, :status => status }

        format.jsone {
          root = extjs_options[:standard_crud] ? target_model_to_underscore : :data
          render :json => { :ns => target_model_to_underscore, root => @target, :success => true },
                 :status => status
        }
      end
    end

    def write_action_error_response
      respond_to do |format|
        format.html {
          flash[:notice] = '#{target_model.to_s.underscore} was unable to save. Some errors occured.'
          render :action => :new
        }

        # 406 Not acceptable
        format.xml {
          render :xml => {
                   :success => false,
                   :errors => build_response(target_model_to_underscore, @target.errors) }.to_xml,
                 :status => :not_acceptable
        }

        format.yaml {
          render :text => @target.errors.to_yaml,
                 :status => :not_acceptable
        }

        format.json {
          render :json => {
                   :success => false,
                   :errors => build_response(target_model_to_underscore, @target.errors) }.to_json,
                   :status => :not_acceptable
        }

        format.jsone {
          render :json => {
                   :success => false,
                   :errors => build_response(target_model_to_underscore, @target.errors) }.to_json,
                   :status => :not_acceptable
        }
      end
    end

    def x_sendfile
      return if !ActiveRest::Configuration.config[:x_sendfile] ||
                @targets.length < ActiveRest::Configuration.config[:default_pagination_page_size]

      # DEFAULT
      cache_file_name =  UUID.timestamp_create.to_s
      #cache_file_name = Digest::MD5.hexdigest(request.env['REMOTE_ADDR']+'_'+request.env['REQUEST_URI'])
      #cache_file_name += '.'+params[:format] if params[:format]
      cache_full_path_file_name = File.join(ActiveRest::Configuration.config[:cache_path], cache_file_name)

      #unless File.exists?(cache_full_path_file_name)
      f = File.new(cache_full_path_file_name,  "w+")
      f << response.body
      f.close

      send_file cache_full_path_file_name,
                :x_sendfile => true
    end
  end

end
end
end
