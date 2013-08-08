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

module ActionDispatch #:nodoc:
module Routing #:nodoc:
class Mapper #:nodoc:

module Resources
  def aresources(*resources, &block)
    resources(*resources) do
      collection do
        get :schema
      end

      yield if block_given?
    end
  end
end

end
end
end
