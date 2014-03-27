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

class Capability
  READABLE = 0x1
  WRITABLE = 0x2
  CREATABLE = 0x4

  attr_accessor :name
  attr_accessor :interface

  attr_accessor :attr_acc
  attr_accessor :actions

  attr_reader :allow_all_actions
  attr_reader :default_readable
  attr_reader :default_writable
  attr_reader :default_creatable

  def initialize(name, interface, h = {})
    raise ArgumentError, 'Name can not be null' if !name

    @name = name
    @interface = interface

    @attr_acc = {}
    @actions = {}

    @allow_all_actions = false
    @default_readable = false
    @default_writable = false
    @default_creatable = false

    h.each { |k,v| send("#{k}=", v) }
  end

  def copy_actions_from(capa)
    @interface.capabilities[capa].actions.each do |k,v|
      @actions[k] = v
    end
  end

  def copy_attributes_from(capa)
    @interface.capabilities[capa].attr_acc.each do |k,v|
      @attr_acc[k] ||= 0
      @attr_acc[k] |= v
    end
  end

  def copy_from(capa)
    copy_actions_from(capa)
    copy_attributes_from(capa)
  end

  def template(capa)
    @interface.templates[capa].actions.each do |k,v|
      @actions[k] = v
    end

    @interface.templates[capa].attr_acc.each do |k,v|
      @attr_acc[k] ||= 0
      @attr_acc[k] |= v
    end
  end

  def default_readable!
    @default_readable = true
  end

  def default_writable!
    @default_writable = true
  end

  def default_creatable!
    @default_creatable = true
  end

  def allow_all_actions!
    @allow_all_actions = true
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

  def creatable(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] |= CREATABLE
  end

  def not_creatable(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] &= ~CREATABLE
  end

  def rw(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] |= READABLE | WRITABLE
  end

  def rwc(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] |= READABLE | WRITABLE | CREATABLE
  end

  def no_access(name, &block)
    @attr_acc[name.to_sym] ||= 0
    @attr_acc[name.to_sym] &= ~(READABLE | WRITABLE | CREATABLE)
  end

  def action_allowed?(name)
    @allow_all_actions || @actions[name.to_sym]
  end

  def allowed_actions
    actions = @interface.actions.keys
    actions &= @actions.select { |k,v| v }.keys if !@allow_all_actions
    actions
  end

  def readable?(name)
    @attr_acc[name.to_sym] ? ((@attr_acc[name.to_sym] & READABLE) != 0) : @default_readable
  end

  def writable?(name)
    @attr_acc[name.to_sym] ? ((@attr_acc[name.to_sym] & WRITABLE) != 0) : @default_writable
  end

  def creatable?(name)
    @attr_acc[name.to_sym] ? ((@attr_acc[name.to_sym] & CREATABLE) != 0) : @default_creatable
  end
end

end

end
end
