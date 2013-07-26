
module ActiveRest
module Model
class Interface

class Capability
  READABLE = 0x1
  WRITABLE = 0x2

  attr_accessor :name

  attr_accessor :attr_acc

  def initialize(name, interface, h = {})
    raise ArgumentError, 'Name can not be null' if !name

    @name = name
    @attr_acc = {}

    @default_readable = false
    @default_writable = false

    h.each { |k,v| send("#{k}=", v) }
  end

  def default_readable!
    @default_readable = true
  end

  def default_writable!
    @default_writable = true
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

  def readable?(name)
    @attr_acc[name.to_sym] ? ((@attr_acc[name.to_sym] & READABLE) != 0) : @default_readable
  end

  def writable?(name)
    @attr_acc[name.to_sym] ? ((@attr_acc[name.to_sym] & WRITABLE) != 0) : @default_writable
  end
end

end

end
end
