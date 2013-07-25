#
# ActiveRest
#
# Copyright (C) 2008-2012, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

module ActiveRest
module Controller

module Rescuer

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'yes', 'Y', 'YES', :true, :t]
  def is_true?(val)
    TRUE_VALUES.include?(val)
  end

  # Rescue action for ActiveRest::Exception kind of exceptions
  #
  def ar_exception_rescue_action(e)

    log_level = :warn
    log_level = e.log_level if e.respond_to?(:log_level)

    if log_level != :none
      message = "\nRendered exception: #{e.class} (#{e.message}):\n"
      message << "  " << e.backtrace.join("\n  ")
      logger.send(log_level, "#{message}\n\n")
    end

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => e.status
    else
      res = {
        :reason => :exception,
        :short_msg => e.message,
        :long_msg => '',
        :retry_possible => false,
        :additional_info => "Exception of class '#{e.class}'",
      }

      res.merge!(e.public_data) if e.respond_to?(:public_data)

      if request.local? || Rails.application.config.consider_all_requests_local
        res.merge!(e.private_data) if e.respond_to?(:private_data)

        res[:annotated_source_code] = e.annoted_source_code.to_s if e.respond_to?(:annoted_source_code)
        res[:backtrace] = e.backtrace
      end

      status_code = e.respond_to?(:http_status_code) ? e.http_status_code : 500

      respond_to do |format|
        format.html { raise e }
        format.xml { render :xml => res, :status => status_code }
        format.yaml { render :yaml => res, :status => status_code }
        format.json { render :json => res, :status => status_code }
        yield(format, res, status_code) if block_given?
      end
    end
  end
end

end
end
