#
# ActiveRest
#
# Copyright (C) 2008-2013, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

module ActiveRest
module Controller

module Validations

  class ActiveRecordSucks < Exception ; end

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

  protected

  def validate_create
    ar_authorize_model_action(:action => :create)
    resource = ar_model.ar_new(:rest, @request_resource, :aaa_context => @aaa_context)

    begin
      ActiveRecord::Base.transaction do
        if !resource.valid?
          raise ActiveRest::Exception::UnprocessableEntity.new('The form is invalid',
                  :errors =>  resource.errors.to_hash,
                  :retry_possible => false)
        end

        raise ActiveRecordSucks
      end
    rescue ActiveRecordSucks
    end

    respond_to do |format|
      format.any { render :nothing => true, :status => :accepted }
    end
  end

  def validate_update
    ar_retrieve_resource
    ar_authorize_action(:action => :update)

    begin
      ActiveRecord::Base.transaction do
        ar_model.interfaces[:rest].apply_update_attributes(resource, @request_resource)

        if !resource.valid?
          raise ActiveRest::Exception::UnprocessableEntity.new('The form is invalid',
                  :errors =>  resource.errors.to_hash,
                  :retry_possible => false)
        end

        raise ActiveRecordSucks
      end
    rescue ActiveRecordSucks
    end

    respond_to do |format|
      format.any { render :nothing => true, :status => :accepted }
    end
  end
end

end
end
