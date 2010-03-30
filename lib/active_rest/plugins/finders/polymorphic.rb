#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Plugins::Finders
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>,
#          Angelo Grossini <angelo@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: polymorphic.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Plugins
module Finders

  module Polymorphic

    #
    # This finder can perform ONLY polymorphic queries where the target model go
    # ONE step down ...
    #
    # target_model.polymorphic_association(id,type) --> class_1
    #                                               --> class_2
    #                                               --> ..
    #                                               --> class_N
    #
    # but DOES NOT work where
    #
    # target_model.polymorphic_association(id,type) --> class_1.polymorphic_association(id,type) --> class_A
    #                                               --> class_2
    #                                               --> ..
    #                                               --> class_N
    #

    protected

    def self.registry_filters
      # polymorphic MUST be passed only when Finder::Auto is used at application level
      # to help it to switch automatically to the correct Finder.
      # This is because basic and polymorphic share almost the same filter options
      return ['polymorphic', 'like', 'fields']
    end

    #
    # This finder will work on two distinct steps
    # 1) collect a list of IDs doing some queries with a dedicated set of model annotation
    # 2) collect fields belongin to the model
    #
    # Example:
    # rest_controller_for MyController, :index_options => {
    #          :finder => :polymorphic,
    #          :polymorphic => {
    #              :filter_field => :owner_name, # the incoming parameter to catch (maybe even declare as virtual_attribute but is not important)
    #              :select=>
    #                [{:table_name => 'admin_people', # this is the real table name
    #                  :fields => [:first_name, :last_name], # which fields we want to query
    #                  :join_id => :parent_table_id, # the field name keeping the polymorphic id
    #                  :join_type => :parent_table_type, # the field name keeping polymorphic ruby class name
    #                  :join_value => 'Hel::Admin::Person'}, # want se must match in join_type field
    #                 {:table_name => 'admin_organizations',
    #                  :fields => :name,
    #                  :join_id => :parent_table_id,
    #                  :join_type => :parent_table_type,
    #                  :join_value => 'Hel::Admin::Organization'}
    #                ]
    #              }
    #           } # eo index_options
    #
    def self.build_conditions(target_model, params, options={})

      #puts '-'*40
      #puts "target_model : #{target_model.inspect}"
      #puts "params : #{params.inspect}"
      #puts "options : #{options.inspect}"
      #puts '-'*40
      ids = []

      # setup target_model table, read filter_field to insert in query
      t1 = target_model.quoted_table_name
      pk = target_model.connection.quote_column_name(:id)
      filter_field = options[:polymorphic][:filter_field]
      options[:polymorphic][:select] = [options[:polymorphic][:select]] unless options[:polymorphic][:select].is_a?(Array)

      # setup two arrays for incomin fields and values (in like conditions)
      p_fields = []
      p_like = []

      # decode like params and read join condition
      p_fields = ActiveSupport::JSON::decode(params[:fields]) if params[:fields]
      # find the position of our polymorphic field and later read the corresponding like value
      idx = p_fields.index(filter_field.to_s)
      idx = 0 if idx.nil?
      p_like = ActiveSupport::JSON::decode(params[:like]) if params[:like]
      p_like = [p_like] if !p_like.is_a?(Array)
      join_condition = (params[:jc].nil?) ? ' AND ' : " #{params[:jc]} "

      # 1) can we perform queries?
      if p_fields.length > 0 && p_like.length > 0
        if p_like[idx] != ''
          # loop on each select query to be run and collect ids
          options[:polymorphic][:select].each do |poly|
            t2 = target_model.connection.quote_column_name(poly[:table_name])
            jid = target_model.connection.quote_column_name(poly[:join_id])
            jv = poly[:join_value]
            jt = target_model.connection.quote_column_name(poly[:join_type])
            fields = poly[:fields]
            fields = [fields] unless fields.is_a?(Array)

            #puts "t1: #{t1}"
            #puts "t2: #{t2}"
            #puts "jf: #{jf}"
            #puts "fields: #{fields.inspect}"

            # prepare and execute the query
            conditions = fields.collect {|x| "#{t2}.#{target_model.connection.quote_column_name(x)} LIKE '%#{p_like[idx]}%'"  }.join(join_condition)
            sql = "SELECT #{t1}.#{pk} FROM #{t1}, #{t2} WHERE #{t1}.#{jid} = #{t2}.#{pk} AND  #{t1}.#{jt} = '#{jv}' AND (#{conditions})"
            #puts "QUERY: #{sql}"
            result_ids = target_model.connection.execute(sql)
            result_ids.each do |x|
              ids << x[0]
            end
          end
          #puts "RESULTING IDS: #{ids.inspect}"
        end
      end

      # 2) add filter looking in column_name
      own_fields_conditions = []
      p_fields.each_index do |i|
        unless i == idx # skip the polymorphic filter
          if target_model.column_names.include?(p_fields[i]) # avoid any unrelated field
            f = target_model.connection.quote_column_name(p_fields[i])
            own_fields_conditions << "#{t1}.#{f} LIKE '%#{p_like[i]}%'"
          end
        end
      end

      # what must be returned ??
      c = []
      c << "id IN (#{ids.join(', ')})" if ids.length > 0
      c << "#{own_fields_conditions.join(join_condition)}" if (own_fields_conditions.length >0)


      # 3) append AND criteria if there is a XXX_id (can be a parent object - has many relation)
      if !options[:condition_parent].nil?
        where = c.join(join_condition)
        where = (where != '') ?  (where +' AND '+ options[:condition_parent]) : options[:condition_parent]
        hash_conditions = {:conditions => [ where , options[:criteria_parent] ] }
      else
        hash_conditions = {:conditions => c.join(join_condition) }
      end

      #puts "FINAL CONDITIONS --> #{hash_conditions.inspect}"
      return hash_conditions

    end # eo build_conditions
  end

end
end
end
