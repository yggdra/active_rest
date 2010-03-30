#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Helpers::Routes::Mapper
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: mapper.rb 5105 2009-09-03 17:50:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Helpers
module Routes

  module Mapper

    BASE_OPTIONS = {
      :collection => {
        :schema => :get
      }.freeze
    }

    ROUTES = {}
    AS = {} # relations with :as keyword pointing to a polymorphic association
    POLYMORPHIC = {} # model having polymorphic assiciation
    THROUGH_OR_HABTM = {} # has many through OR has and belongs to many

    #
    # return the url from a specific controller
    #
    def self.url_for(controller)
      controller = controller.to_s.pluralize.to_sym
      return ROUTES.has_key?(controller) ? ROUTES[controller][:url] : nil
    end

    #
    # return only the path prefix for a controller
    # see controller.rb and dinamic :member def;
    #
    # controller.rb will use the real polymorphic_url and not active_rest_polymorphic_url
    #
    def self.get_path_prefix_for(controller)
      controller = controller.to_s.pluralize.to_sym
      return ROUTES.has_key?(controller) ? ROUTES[controller][:path_prefix] : nil
    end

    #
    # return the un-evaled string for has_many through finder OR has and belongs to many
    #
    # model = target model for this controller
    # params = params given to the controller
    #
    def self.has_many_through_or_habtm?(model, params)
      return false unless THROUGH_OR_HABTM.has_key?(model.to_s)

      params.keys.each do |k|
        if params[k]
          THROUGH_OR_HABTM[model.to_s].each do |r|
            return r[:finder_replace] % params[k] if r[:param_id] == k
          end
        end
      end

      return false # no result found
    end


    protected

    #
    # merge config/routes.rb options with active_rest base options
    #
    def self.merge(params)
      # do we want active rest to add extra routes to our controller?
      if (!params[:act_as_plain_rest].nil?) and (params[:act_as_plain_rest]==true)
        options= {}
        options.merge!({ :collection => params[:collection]}) if params.has_key?(:collection)
        params.delete(:collection)
        params.delete(:map)
        options.merge(params)
      else
        options = Marshal.load(Marshal.dump(BASE_OPTIONS)) # do a deep copy
        options[:collection].merge!(params[:collection]) if params.has_key?(:collection)
        assoc = associations(params[:model])

        params.delete(:collection)
        params.delete(:map)

        # deep merge options, assoc and params
        (options.keys + assoc.keys + params.keys).uniq.each do | key |
          options[key] ||= assoc[key] || params[key]
          assoc[key] ||= options[key]
          params[key] ||= options[key]

          case options[key].class.to_s
          when 'Hash'
            options[key].merge!(params[key])
            options[key].merge!(assoc[key])
          when 'Array'
            options[key] += params[key]
            options[key] += assoc[key]
            options[key].uniq!
          else
            options[key] = assoc[key].blank? ? (params[key].blank? ? options[key] : params[key]) : assoc[key]
          end
        end
      end

      # clean all unwanted or already merged arguments
      return options
    end

    #
    # return an hash composed of :has_many => [...] and :member => [...]
    #
    def self.associations(model)
      hash = {}
      #puts "--->#{model.reflections.inspect}"
      model.reflections.keys.each do | k |
        #puts "\n\n #{k} -- #{model.reflections[k].inspect}"

        if model.reflections[k].macro == :has_one or model.reflections[k].macro == :belongs_to
          hash[:member] = {} if !hash.has_key?(:member)

          if ActiveRest::Configuration[:members_crud]
            # crud for has_many and belongs_to
            hash[:member][k.to_sym] = :any
            hash[:member]["#{k}_new".to_sym] = :get
            hash[:member]["#{k}_edit".to_sym] = :get
          else
            # has_many and belongs_to redirects to member controller
            hash[:member][k.to_sym] = :get
          end
          #hash[:member] << model.reflections[k].class_name.demodulize.tableize #downcase.pluralize
        end

        if (model.reflections[k].macro == :has_many || model.reflections[k].macro == :has_and_belongs_to_many)
          hash[:has_many] = {} if !hash.has_key?(:has_many)
          hash[:has_many][k] = model.reflections[k].klass
          #begin
          #  hash[:has_many] << model.reflections[k].class_name.demodulize.tableize #downcase.pluralize
          #rescue
          #  hash[:has_many] << model.reflections[k].name # not sure about it
          #end

          detect_has_many_through_or_habtm(model, k)
        end

        detect_and_collect_polymorphic_association(model, k)
      end

      return hash
    end

    #
    # detect has many through associations or has and belongs to many (habtm)
    #
    def self.detect_has_many_through_or_habtm(model, reflection_key)
      # has many through
      if model.reflections[reflection_key].options.has_key?(:through)
        begin
          class_name = model.reflections[reflection_key].class_name
          this_has_many_through = {}

          if model.reflections[reflection_key].options.has_key?(:source)
            expected_id_param = "#{model.reflections[reflection_key].options[:source]}_id" # just a convention
            refered_model = eval(class_name, nil, __FILE__, __LINE__)
            refered_model.reflections.each do | r|

              begin
                if r[1].source_reflection.class_name == model.to_s # found our model!
                  this_has_many_through = {
                    :param_id => expected_id_param,
                    :finder_replace => class_name+'.find(%s).'+r[0].to_s # build someting Hel::Admin::Organization.find(%s).identities
                  }
                end
              rescue
                #pass - no source_reflection
              end
            end
          end

          THROUGH_OR_HABTM[model.to_s]= [] unless THROUGH_OR_HABTM.has_key?(model.to_s)
          THROUGH_OR_HABTM[model.to_s] << this_has_many_through unless this_has_many_through.blank?
        rescue
          puts "Found '#{model}' with a has_many through on '#{reflection_key}' without :class_name !! Please, provide it."
        end
      end

      # has and belongs to many
      if model.reflections[reflection_key].macro == :has_and_belongs_to_many
        class_name = model.reflections[reflection_key].class_name.to_s
        habtm = {
          :param_id => model.reflections[reflection_key].primary_key_name,
          :finder_replace => model.to_s+'.find(%s).'+model.reflections[reflection_key].name.to_s # build someting Hel::Admin::Organization.find(%s).identities
        }

        THROUGH_OR_HABTM[class_name]= [] unless THROUGH_OR_HABTM.has_key?(class_name)
        THROUGH_OR_HABTM[class_name] << habtm unless habtm.blank?
      end
    end

    #
    # detect polymorphic association
    #
    def self.detect_and_collect_polymorphic_association(model, reflection_key)
      if model.reflections[reflection_key].options.has_key?(:as)
        #puts model.to_s.demodulize.downcase.singularize.inspect

        # @options={:as => :destination, :extend => [],
        # :dependent => :nullify, :class_name => 'Hel::Telephony::Identifier'},
        # @name=:identifiers, @primary_key_name='destination_id'
        key = '%s_%s' % [ model.reflections[reflection_key].options[:as], model.to_s.demodulize.downcase.singularize+'_id' ]
        unless AS.has_key?(key)
          AS[key] = {
            :as => model.reflections[reflection_key].options[:as],
            :reflection => reflection_key,
            :param_id =>  model.to_s.demodulize.downcase.singularize+'_id', # es. params { :endpoint_id => 1 }
            :map_to_model => model.to_s,
            :association_class_name => model.reflections[reflection_key].options[:class_name],
            :map_to_primary_key => model.reflections[reflection_key].primary_key_name
          }
        end
      end

      if model.reflections[reflection_key].options.has_key?(:polymorphic)
        if model.reflections[reflection_key].options[:polymorphic]
          # @options={:foreign_type => 'destination_type', :polymorphic => true}, @name=:destination>
          unless POLYMORPHIC.has_key?(model.to_s)
            POLYMORPHIC[model.to_s] = {
              :reflection => reflection_key,
              :foreign_type => model.reflections[reflection_key].options[:foreign_type],
              :reflection_obj => model.reflections[reflection_key]
            }
          end
        end
      end
    end
  end

end
end
end
