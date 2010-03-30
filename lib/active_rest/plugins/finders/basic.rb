#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Plugins::Finders
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: basic.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Plugins
module Finders

  module Basic

  protected

    def self.registry_filters
      # basic MUST be passed only when Finder::Auto is used at application level
      # to help it to switch automatically to the correct Finder.
      # This is because basic and polymorphic share almost the same filter options
      return ['basic', 'query', 'like', 'fields']
    end


    #
    # This method is called by ActiveRest::Helpers::Pagination::Core
    # redeclare it in each new finder
    #
    #
    # ARGUMENTS
    # -----------------------------------------
    # - sort: name of field to base ordering
    # - dir: ordering direction (asc, desc)
    # - limit: any positive number will limit the page results
    # - offset: any positive number will delimit left-side limit
    # - fields: a string or an array ([fld1,fld2...]) of fields to search in
    # - like: a string or an array  ([fld1,fld2...]) of criteria to macth with like %% operator
    # - query: a string or an array ([fld1,fld2...]) of criteria with exact matching
    # - jc: a string rappresenting the join condition (AND is default)
    # notes
    # -----
    # query --> ?fields=['name','surname','nick']&query=['mario','rossi']&like=['red']
    #
    # query will precede like keyword so the result will be:
    # name='mario' AND surname='rossi' AND nick LIKE '%red%'
    #
    #
    # PLUS
    # -----------------------------------------
    # extra_conditions -> force extra condition (options given to the controller)
    # attr_alternative_filter -> if model has annotation for alternative filter, use it;
    #                            this make easy query for example 'field_id=1232' and let ActiveRest
    #                            convert it to the alternative, example other_table.field_label -
    #                            THIS IS DONE with JOIN !
    #
    #
    # NOTE: pay attention -- can clash with option :join given at controller level
    #
    #
    def self.build_conditions(target_model, params, options={})
      #puts "target_model : #{target_model.inspect}"
      #puts "params : #{params.inspect}"
      #puts "options : #{options.inspect}"
      returning options_final_hash = {} do
        search_conditions = []

        # are there any arguments to be always applied?
        # those arguments override any incoming field with the same key!
        override_conditions = {}
        override_conditions = options[:extra_conditions] if options.has_key?(:extra_conditions)


        #
        # example
        # ?fields=['name','surname','nick']&query=['mario','rossi']&like=['red']
        #
        # produces
        # name='mario' AND surname='rossi' AND nick LIKE '%red%'
        #
        # NOTE: 'query' precedences 'like'
        #

        fields = []
        like = []
        query = []

        if params[:fields]
          fields = ActiveSupport::JSON::decode(params[:fields])
          fields = [fields] if !fields.is_a?(Array)
        end

        if params[:query]
          query = ActiveSupport::JSON::decode(params[:query])
          query = [query] if !query.is_a?(Array)
        end

        if params[:like]
          like = ActiveSupport::JSON::decode(params[:like])
          like = [like] if !like.is_a?(Array)
        end

        conds= []
        criterias ={}

        joins = []
        if fields.length == (like.length + query.length) # fields match criterias?
          fields.each_index do |i|
            unless override_conditions.keys.include?(fields[i].to_sym) # do not insert field that maybe be found in :extra_index_conditions returnin hash

              # this fields is an alternative filter?
              alternative = target_model.attr_alternative_filter(fields[i].to_sym)

              if alternative
                if !alternative.has_key?(:refer_to) # ok, it must be a hash with model and field
                  table = eval(target_model.reflections[alternative[:model]].class_name).quoted_table_name
                  alt_field = alternative[:field]

                  joins << alternative[:model]

                  conds << "#{table}.`#{alt_field.to_s}` " + ( (query.length>0) ? "= :#{alt_field.to_s} " : "LIKE :#{alt_field.to_s}" )
                  criterias[ alt_field ] = ( (query.length>0) ? query.shift.to_s : '%'+like.shift .to_s+'%' )
                else
                  # this field has alternatives but in this case it's a refer_to (used only client side)
                  conds << "#{target_model.quoted_table_name}.`#{fields[i]}` " + ( (query.length>0) ? "= :#{fields[i]} " : "LIKE :#{fields[i]}" )
                  criterias[ eval(":#{fields[i]}") ] = ( (query.length>0) ? query.shift.to_s : '%'+like.shift .to_s+'%' )
                end
              else
                # no alternatives ... is it a field? if yes include it!
                if target_model.column_names.include?(fields[i])
                   conds << "#{target_model.quoted_table_name}.`#{fields[i]}` " + ( (query.length>0) ? "= :#{fields[i]} " : "LIKE :#{fields[i]}" )
                   criterias[ eval(":#{fields[i]}") ] = ( (query.length>0) ? query.shift.to_s : '%'+like.shift .to_s+'%' )
                end
              end

            end # eo unless

          end
        end

        join_condition = (params[:jc].nil?) ? ' AND ' : ' '+params[:jc]+' '
        conditions = conds.join(join_condition)

        # append AND criteria if there is a XXX_id (can be a parent object - has many relation)
        if !options[:condition_parent].nil?
          conditions = (conditions=='') ? options[:condition_parent] : '('+conditions+') AND '+options[:condition_parent]
          criterias.merge!(options[:criteria_parent])
        end

        #
        # loop over extra conditions... maybe there are ones that override params filter and
        # others that must be just appended
        #
        if options.has_key?(:extra_conditions)
          override_conditions.each do |key, value|
            conditions += ' AND ' if conditions != ''
            conditions += key.to_s + '= :'+key.to_s
            criterias[key] = value
          end
        end

        options_final_hash.merge!(:conditions => [conditions, criterias] ) unless conditions.empty?
        options_final_hash.merge!(:joins => joins) unless joins.empty?

        options_final_hash
      end
    end
  end

end
end
end
