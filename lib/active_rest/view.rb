#
# ActiveRest
#
# Copyright (C) 2008-2014, Intercom Srl, Daniele Orlandi
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

  attr_accessor :capabilities
  attr_accessor :shortcut_capabilities

  def initialize(name = :anonymous, config = {}, &block)
    @name = name

    @definition = {}
    @empty = false
    @with_type = true
    @with_perms = false
    @per_class = {}

    @extjs_polymorphic_workaround = false

    @eager_loading_hints = []

    @capabilities = []
    @shortcut_capabilities = false

    config.each { |k,v| send("#{k}=", v) }

    self.instance_eval(&block) if block_given?
  end

  def initialize_copy(source)
    @definition = @definition.clone
    @definition.each { |k,v| @definition[k] = v.clone }

    @per_class = @per_class.clone
    @per_class.each { |k,v| @per_class[k] = v.clone }

    @eager_loading_hints = @eager_loading_hints.clone

    @capabilities = @capabilities.clone
    @capabilities.each { |k,v| @capabilities[k] = v.clone }
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
      @subview ||= new_subview
      @subview.attribute(name, &block)
      @subview
    end

    def empty!
      @subview ||= new_subview
      @subview.empty!
      @subview
    end

    def extjs_polymorphic_workaround!
      @subview ||= new_subview
      @subview.extjs_polymorphic_workaround!
      @subview
    end

    def per_class!(name, &block)
      @subview ||= new_subview
      @subview.per_class!(name, &block)
      @subview
    end

    def virtual(type, &block)
      @display = :show
      @virtual_src = block
    end

    def with_type!
      @subview ||= new_subview
      @subview.with_type!
      @subview
    end

    def capabilities(capas)
      @subview ||= new_subview
      @subview.capabilities=(capas)
      @subview
    end

    def shortcut_capabilities!
      @subview ||= new_subview
      @subview.shortcut_capabilities = true
      @subview
    end

    protected

    def new_subview
      View.new(@name, :capabilities => [ :subview ])
    end
  end
end

end
