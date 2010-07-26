#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Actions::Insepctors
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: inspectors.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Controller

  module Inspectors
    #
    # in your controller you can override schema action this way:
    #
    # def assocs
    #   super { |f|
    #     f.format_one { render ... }
    #     f.format_two { render ... }
    #   }
    # end
    #

    def schema(&blk)

      @schema = {
        :_type => model.name,
        :_type_symbolized => model_symbol,
        :_attrs => Hash[*model.columns.collect { |x|
          [x.name, {
            :type => map_column_type(x.type),
            :primary => x.primary,
            :null => x.null,
            :default => x.default,
            :creatable => true,
            :readable => true,
            :writable => true
          }]
        }.flatten]
      }

      if model.respond_to?(:ordered_attributes)
        if model.attribute_groups.has_key?(:virtual_attributes)

          model.ordered_attributes(:virtual_attributes).each do |v|
            type = model.attr_type(v)
            search = model.attr_search(v)
            @schema[v] = {
              :name => v,
              :type => (type.nil?) ? :string : type,
              :primary => false,
              :null => false,
              :default => '',
              :virtual => true,
              :search => (search.nil?) ? false : search
              }
          end
        end
      end

      model.reflections.each { |name, reflection|
        case reflection.macro
        when :composed_of
          @schema[:_attrs][name] = {
            :type => reflection.macro,
          }
        else
          @schema[:_attrs][name] = {
            :type => reflection.macro,
            :embedded => !!(reflection.options[:embedded]),
          }
        end
      }

      respond_to do | format |
        format.xml { render :xml => @schema.to_xml(:dasherize => false) }
        format.yaml { render :text => @schema }
        format.json { render :json => @schema }
        yield(format) if block_given?
      end
    end
    alias ar_schema schema

    private

    def map_column_type(type)
      case type
      when :datetime
        :timestamp
      else
        type
      end
    end
  end

end
end
