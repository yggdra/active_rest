#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Actions::Rest
#
# Author:: Angelo Grossini <angelo@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: rest.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
# CRUD for has_many or belongs_to resources
#


module ActiveRest
module Controller
module Actions

  module MembersRest

    private

    def member_model(member_name)
      target_model.reflections[member_name.to_sym].class_name.constantize
    end

    def member_model_to_underscore(member_name)
      tamrget_model.reflections[member_name.to_sym].class_name.underscore.gsub(/\//, '_')
    end

    # GET /target/1/member
    def member_show(association, member_name)
      if @member.nil?
        raise NotFound
      else
        member_output(association, member_name)
      end
    end

    # GET /target/1/member_new
    def member_new(association, member_name)
      member_output(association, member_name)
    end


    # POST /target/1/member
    # if parameter '_only_validation' is present only validation actions will be runned;
    # see ActiveRest::Controller::Actions::Validations
    def member_create(association, member_name)
      if association == :belongs_to
        raise NotAcceptable
      end

      saved = false
      #TODO 409!

      begin
        member_model(member_name).transaction do
          @member = member_model(member_name).new(params[member_model_to_underscore(member_name)])
          @target.send("#{member_name}=".to_sym, @member)
          saved = @target.save!
          @target.reload
          @member = @target.member
        end
      rescue ActiveRecord::RecordInvalid
        # don't do nothing, let the controller respond
      end

      if is_true?(params[:_suppress_response])
        render :nothing => true, :status => status
      else
        if saved
          member_write_action_successful_response(:created)
        else
          member_write_action_error_response(member_name)
        end
      end
    rescue Exception => ex
      require 'pp'
      Rails.logger.error ex.pretty_inspect
      Rails.logger.error ex.backtrace.pretty_inspect
      raise BadRequest # something nasty has happend
    end

    # GET /target/1/member_edit
    def member_edit(association, member_name)
      if @member.nil?
        raise NotFound
      end
      member_output(association, member_name)
    end

    # PUT /target/1/member
    # if parameter '_only_validation' is present only validation actions will be runned;
    # see ActiveRest::Controller::Actions::Validations
    def member_update(association, member_name)
      if @member.nil?
        raise NotFound
      end
      saved = false
      begin
        member_model(member_name).transaction do
          saved = @member.update_attributes!(params[member_model_to_underscore(member_name)])
          @member.reload
        end
      rescue ActiveRecord::RecordInvalid => ex
        # don't do nothing, let the controller respond
      end

      if is_true?(params[:_suppress_response])
        render :nothing => true, :status => status
      else
        if saved
          member_write_action_successful_response(:created)
        else
          member_write_action_error_response(member_name)
        end
      end
    rescue Exception => ex
      require 'pp'
      Rails.logger.error ex.pretty_inspect
      Rails.logger.error ex.backtrace.pretty_inspect
      raise BadRequest # something nasty has happend
    end


    # DELETE /target/1/member
    def member_destroy(association, member_name)
      if association == :belongs_to
        raise NotAcceptable
      end
      if @member.nil?
        raise NotFound
      else
        @member.destroy
        respond_to do |format|
          format.html {
            flash[:notice] = '#{member_model_to_underscore(member_name)} was successfully destroyed.'
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
    end

    def member_output(association, member_name)
      respond_to do |format|
        format.html
        format.xml { render :xml => [@member].to_xml(:root => member_model_to_underscore(member_name)) } ## see above note
        format.yaml { render :text => target.to_yaml }
        format.json { render :json => @member }
        format.jsone {
          root = member_model_to_underscore(member_name)
          render :json => { :ns => member_model_to_underscore(member_name), root => @member, :success => true }
        }
      end
    end

    private

    def member_write_action_successful_response(status)
      respond_to do |format|
        format.html {
          flash[:notice] = 'Operation successful.'
          render :action => :edit, :status => status
        }

        # 201 Created
        format.xml { render :xml => @member.to_xml(:root => member_model_to_underscore(member_name)), :status => status }
        format.json { render :json => @member, :status => status }
        format.yaml { render :text => @member.to_yaml, :status => status }

        # extjs prevede come risposte a create o update di usare il namespace, non 'data' come root per la risposta...
        format.jsone {
          root = member_model_to_underscore(member_name)
          render :json => { :ns => member_model_to_underscore(member_name), root => @member.attributes, :success => true },
                 :status => status
        }
      end
    end

    def member_write_action_error_respnse(member_name)
      respond_to do |format|
        format.html {
          flash[:notice] = '#{member_model_to_underscore(member_name)} was unable to save. Some errors occured.'
          render :action => :edit
        }
        # 406 Not acceptable
        format.xml {
          render :xml => {
                   :success => false,
                   :errors => build_response(member_model_to_underscore(member_name), @member.errors) }.to_xml,
                 :status => :not_acceptable
        }

        format.yaml { render :text => @member.to_yaml, :status => :not_acceptable }

        format.json {
          render :json => {
                   :success => false,
                   :errors => build_response(member_model_to_underscore(member_name), @member.errors) }.to_json,
                 :status => :not_acceptable
        }

        format.jsone {
          render :json => {
                   :success => false,
                   :errors => build_response(member_model_to_underscore(member_name), @member.errors) }.to_json,
                 :status => :not_acceptable
        }
      end
    end
  end

end
end
end
