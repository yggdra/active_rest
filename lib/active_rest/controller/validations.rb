#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Actions::Validations
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: validations.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Controller
  module Validations

    def self.included(base)
      #:nodoc:
    end

    #
    # VALIDATIONS
    #
    # NOTE: these actions are not called directly ! check_validation_action do the trick
    #
    # format.html --> this is not the place for it :-) only remote validations for other formats
    #
    #
    # in your controller you can override these methods this way:
    #
    # def verify_authenticity_token
    #   super { |f, valid|
    #     if valid
    #       f.format_one { render ... }
    #     else
    #       f.format_one { render ... }
    #     end
    #   }
    # end
    #

    def validate_create
      target = model.new
      guard_protected_attributes = self.respond_to?(:guard_protected_attributes) ? send(:guard_protected_attributes) : true
      target.send(:attributes=, params[model_symbol], guard_protected_attributes)

      validation_response(target)
    end

    def validate_update
      find_target
      guard_protected_attributes = self.respond_to?(:guard_protected_attributes) ? send(:guard_protected_attributes) : true
      @target.send(:attributes=, params[model_symbol], guard_protected_attributes)

      validation_response(target)
    end

    private

    def validation_response(target, &blk)
      valid = target.valid?
      status = valid ? :accepted : :not_acceptable

      if is_true?(params[:_suppress_response])
        render :nothing => true, :status => status
      else
        respond_to do | format |
          format.xml {
            render :xml => {
                :success => valid,
                :errors => build_response(model_symbol, target.errors) }.to_xml,
              :status => status
          }

          format.yaml {
            render :text => {
                :success => valid,
                :errors => build_response(model_symbol, target.errors) }.to_yaml,
              :status => status
          }

          format.json {
            render :json => {
                :success => valid,
                :errors => build_response(model_symbol, target.errors) }.to_json,
              :status => status
          }

          yield(format, valid, status) if block_given?
        end
      end
    end
    alias ar_validation_response validation_response

    #
    # prepare a response format that when decoded in json looks like this:
    #
    # [{"hel_country[name]": "can't be blank"}, ... ]
    #
    # the default behaviour is to return a namespace field, but something is useful
    # have only the field... an example is the datagrid column naming, here adopted
    #
    def build_response(namespace, errors)
      risp = []
      errors.each do |name, message|
          risp << { "#{namespace}[#{name}]" => message }
      end

      return risp
    end

    #
    # if the form contains a _only_validation field then RESTful request is considered a "dry-run" and gets routed to a different
    # action named validate_*
    #
    def check_validation_action
      if is_true?(params[:_only_validation])
        send 'validate_' + action_name
      end
    end

  end

end
end
