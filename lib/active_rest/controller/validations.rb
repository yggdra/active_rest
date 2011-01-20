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
      guard_protected_attributes = self.respond_to?(:guard_protected_attributes) ? send(:guard_protected_attributes) : true
      target.send(:attributes=, params[model_symbol], guard_protected_attributes)

      if !target.valid?
        raise UnprocessableEntity.new('The form is invalid',
                :per_field_msgs => target.errors.inject({}) { |h, (k, v)| h["#{model_symbol}[#{k}]"] = v; h },
                :retry_possible => false)
      end

      render :nothing => true
    end

    def validate_update
      find_target
      guard_protected_attributes = self.respond_to?(:guard_protected_attributes) ? send(:guard_protected_attributes) : true
      @target.send(:attributes=, params[model_symbol], guard_protected_attributes)

      if !target.valid?
        raise UnprocessableEntity.new('The form is invalid',
                :per_field_msgs => target.errors.inject({}) { |h, (k, v)| h["#{model_symbol}[#{k}]"] = v; h },
                :retry_possible => false)
      end

      render :nothing => true
    end
  end

end
end
