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
      model.interfaces[:rest].apply_creation_attributes(target, @request_resource)

      if !target.valid?
        raise ActiveRest::Exception::UnprocessableEntity.new('The form is invalid',
                :errors =>  target.errors.to_hash,
                :retry_possible => false)
      end

      respond_to do |format|
        format.any { render :nothing => true }
      end
    end

    def validate_update
      find_target

      model.interfaces[:rest].apply_update_attributes(target, @request_resource)

      if !target.valid?
        raise ActiveRest::Exception::UnprocessableEntity.new('The form is invalid',
                :errors =>  target.errors.to_hash,
                :retry_possible => false)
      end

      respond_to do |format|
        format.any { render :nothing => true }
      end
    end
  end

end
end
