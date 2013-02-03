module ActiveRest

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
end

end
