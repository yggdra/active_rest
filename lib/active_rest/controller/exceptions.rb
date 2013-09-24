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

class Exception < StandardError
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

  class MethodNotAllowed < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :method_not_allowed, public_data, private_data
    end
  end

  class BadRequest < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :bad_request, public_data, private_data
    end
  end

  class Forbidden < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :forbidden, public_data, private_data
    end
  end

  class NotFound < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :not_found, public_data, private_data
    end

    def log_level
      :none
    end
  end

  class NotAcceptable < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :not_acceptable, public_data, private_data
    end
  end

  class UnprocessableEntity < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :unprocessable_entity, public_data, private_data
    end
  end

  class Conflict < Exception
    def initialize(msg = '', public_data = {}, private_data = {})
      super msg, :conflict, public_data, private_data
    end
  end

  class AAAError < Exception
    attr_accessor :reason
    attr_accessor :short_msg
    attr_accessor :headers

    def initialize(opts = {})
      super(opts[:short_msg])

      self.reason = :unknown
      opts.each { |k,v| send "#{k}=", v }
    end


    def to_hash
     {
      :http_status_code => http_status_code,
      :reason => reason,
      :short_msg => short_msg,
     }
    end

    def to_json(opts = {})
      to_hash.to_json
    end

    def to_xml(opts = {})
      to_hash.to_xml
    end
  end

  class AuthenticationError < AAAError
    def initialize(opts)
      super({ :http_status_code => 401 }.merge opts)
    end
  end

  class AuthorizationError < AAAError
    def initialize(opts)
      super({ :http_status_code => 403 }.merge opts)
    end
  end

end

end
end
