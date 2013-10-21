#
# ActiveRest
#
# Copyright (C) 2013-2013, Intercom Srl, Daniele Orlandi
#
# Author:: Daniele Orlandi <daniele@orlandi.com>
#          Lele Forzani <lele@windmill.it>
#          Alfredo Cerutti <acerutti@intercom.it>
#
# License:: You can redistribute it and/or modify it under the terms of the LICENSE file.
#

module ActiveRest
module Model
class Interface

class CapabilityTemplate
  READABLE = 0x1
  WRITABLE = 0x2

  attr_accessor :name

  attr_accessor :attr_acc
  attr_accessor :actions

  def initialize(name, interface, h = {})
    raise ArgumentError, 'Name can not be null' if !name

    @name = name
    @interface = interface

    @attr_acc = {}
    @actions = {}

    h.each { |k,v| send("#{k}=", v) }
  end

  def allow(name)
    @actions[name.to_sym] = true
  end

  def deny(name)
    @actions[name.to_sym] = false
  end

  def readable(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] |= READABLE
  end

  def not_readable(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] &= ~READABLE
  end

  def writable(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] |= WRITABLE
  end

  def not_writable(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] &= ~WRITABLE
  end

  def rw(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] |= READABLE | WRITABLE
  end

  def no_access(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] &= ~(READABLE | WRITABLE)
  end
end

end

end
end
