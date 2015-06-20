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

  protected

  # Rescue action for ActiveRest::Exception kind of exceptions
  #
  def ar_exception_rescue_action(e, opts = {})

    headers.merge!(e.headers) if e.respond_to?(:headers) && e.headers

    log_level = :warn
    log_level = e.log_level if e.respond_to?(:log_level)
    log_level = opts[:log_level] if opts[:log_level]

    if log_level != :none
      message = "\nRendered exception: #{e.class} (#{e.message}):\n"
      message << "  " << e.backtrace.join("\n  ")
      logger.send(log_level, "#{message}\n\n")
    end

    if is_true?(params[:_suppress_response])
      render :nothing => true, :status => e.status
    else
      res = {
        reason: :exception,
        exception_type: e.class.name,
        short_msg: e.message,
        long_msg: e.respond_to?(:long_msg) ? e.long_msg : e.message,
        retry_possible: false,
        additional_info: "Exception of class '#{e.class}'",
        data: {},
      }

      res[:data].merge!(e.public_data) if e.respond_to?(:public_data)

      if request.local? || Rails.application.config.consider_all_requests_local
        res[:data].merge!(e.private_data) if e.respond_to?(:private_data)
        res[:annotated_source_code] = e.annoted_source_code.to_s if e.respond_to?(:annoted_source_code)
        res[:backtrace] = e.backtrace
      end

      status_code = e.respond_to?(:http_status_code) ? e.http_status_code : 500

      respond_to do |format|
        format.xml { render :xml => res, :status => status_code }
        format.yaml { render :yaml => res, :status => status_code }
        format.json { render :json => res, :status => status_code }
        format.text { render :plain => res.awesome_inspect(:plain => true), :status => status_code }
        yield(format, res, status_code) if block_given?
        format.any { render :plain => res.awesome_inspect(:plain => true), :status => status_code }
      end
    end
  end
end

end
end
