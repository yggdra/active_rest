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

class View
  attr_accessor :name
  attr_accessor :definition

  attr_accessor :empty
  attr_accessor :with_type
  attr_accessor :with_perms
  attr_accessor :per_class
  attr_accessor :extjs_polymorphic_workaround
  attr_accessor :eager_loading_hints

  attr_accessor :limit
  attr_accessor :order

  def initialize(name = :anonymous, &block)
    @name = name

    @definition = {}
    @empty = false
    @with_type = true
    @with_perms = false
    @per_class = {}

    @extjs_polymorphic_workaround = false

    @eager_loading_hints = []

    self.instance_eval(&block) if block_given?
  end

  def attr_visible?(attr)
    if @empty
      @definition[attr].display == :show
    else
      @definition[attr].nil? || @definition[attr].display != :hide
    end
  end

  # DSL
  def empty!
    @empty = true
    @with_type = false
    @with_perms = false
  end

  def with_perms!
    @with_perms = true
  end

  def without_perms!
    @with_perms = false
  end

  def with_type!
    @with_type = true
  end

  def without_type!
    @with_type = false
  end

  def attribute(name, &block)
    @definition[name] ||= Attribute.new(name)
    @definition[name].instance_eval(&block)
    @definition[name]
  end

  def per_class!(name, &block)
    @per_class[name] = View.new(@name)
    @per_class[name].instance_eval(&block) if block_given?
    @per_class[name]
  end

  def extjs_polymorphic_workaround!
    @extjs_polymorphic_workaround = true
  end

  def eager_load(*args)
    @eager_loading_hints = args
  end

  class Attribute
    attr_accessor :name
    attr_accessor :display
    attr_accessor :include
    attr_accessor :virtual_src

    attr_accessor :subview

    # These should actually be in collections but we don't yet know the type
    attr_accessor :limit
    attr_accessor :order

    def initialize(name)
      @name = name
      @display = :default
    end

    def include!
      @include = true
      @display = :show
    end

    def exclude!
      @include = false
      @display = :hide
    end

    def show!
      @display = :show
    end

    def hide!
      @display = :hide
    end

    def attribute(name, &block)
      @subview ||= View.new(@name)
      @subview.attribute(name, &block)
      @subview
    end

    def empty!
      @subview ||= View.new(@name)
      @subview.empty!
      @subview
    end

    def extjs_polymorphic_workaround!
      @subview ||= View.new(@name)
      @subview.extjs_polymorphic_workaround!
      @subview
    end

    def per_class!(name, &block)
      @subview ||= View.new(@name)
      @subview.per_class!(name, &block)
      @subview
    end

    def virtual(type, &block)
      @display = :show
      @virtual_src = block
    end
  end
end

end
