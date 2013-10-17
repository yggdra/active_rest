
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

  def action(name)
    @actions[name.to_sym] = true
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
