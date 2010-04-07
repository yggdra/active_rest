#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Core
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>,
#          Angelo Grossini <angelo@intercom.it>
#
# License:: Proprietary
#
# Revision:: $Id: core.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Controller

  module Core

    def self.included(base)
      #:nodoc:
      #include ActiveRest::Helpers::Routes::Mapper
    end

    #
    # in your controller you can override these methods this way:
    #
    # def verify_authenticity_token
    #   super { |f|
    #     f.format_one { render ... }
    #     f.format_two { render ... }
    #   }
    # end
    #

    protected

    #
    # handle authenticity token (html in primis)
    #
    def verify_authenticity_token(&blk)
      respond_to do | format |
        format.html { super }
        format.xml {}
        format.json {}
        format.jsone {}
        format.yaml {}
        blk.call(format) if blk # overriding to handle other format
        format.any { super } # unhandled format? do authenticity token!
      end
    end

    #
    # setup I18n if params has this information
    #
    def prepare_i18n
      I18n.locale = params[:language].to_sym if params[:language]
    end

    #
    # raise a rescue action with forbidden status
    #
    def active_rest_deny_access
    end

    private

    #
    # generic rescue action. when html will handle a block
    #
    def generic_rescue_action(status, &blk)
      respond_to do |format|
        format.html do
          if block_given?
            yield
          else
            render :nothing => true, :status => status
          end
        end

        format.xml { render :nothing => true, :status => status }
        format.yaml  { head :status => status, :nothing => true }
        format.json { render :nothing => true, :status => status }
        format.jsone { render :nothing => true, :status => status }

        blk.call(format) if blk # when overriding to handle other format
        format.any { head :status => status, :nothing => true } # any other format
      end
    end

    #
    # call this to handle all exceptions uncaught
    #
    def rest_interface_rescue_action
      generic_rescue_action(:internal_server_error)
      false
    end

    #
    # model name to underscore, even when namespaced
    #
    def target_model_to_underscore
      target_model.to_s.underscore.gsub(/\//, '_')
    end

    #
    # find a single resource; return object or, if action is not include
    # into a object ruleset, return an hash
    #
    def find_target(options={})
      begin
        joins, select = build_joins

        tid = options[:id] || params[:id]
        options.delete(:id)

        find_options = {}
        find_options[:select] = select unless select.blank?
        find_options[:joins] = joins unless joins.blank?

        @target = target_model.find(tid, find_options)
      rescue
        generic_rescue_action(:not_found)
      end
    end

    #
    # find all with conditions
    #
    def find_targets

      # 1^ prepare basic conditions
      update_model_finder_scope

      pagination_state = update_pagination_state_with_params!(target_model)
      update_model_pagination_scope(pagination_state)

      # 2^ build joins - some finder plugins may change :select and :joins argument or can clash with them
      joins, select = build_joins
      opts[:select] = select unless select.nil?||select.empty?
      opts[:joins] = joins unless joins.nil?||joins.empty?

      preprocessor = index_options[:preprocess]
      if preprocessor && (preprocessor.is_a?(String) || preprocessor.instance_of?(Module))
        preprocessor = preprocessor.constantize if preprocessor.is_a?(String)
        preprocessor = preprocessor.to_s.constantize if preprocessor.is_a?(Symbol)
        opts = preprocessor::preprocess(opts, :params => params)
      end

      # 3^ detect has_many through associations (in that case try to use the right finder)
      hmt_habtm_finder = ActiveRest::Helpers::Routes::Mapper.has_many_through_or_habtm?(target_model, params)

      if hmt_habtm_finder
######FIXME
        resources = eval(hmt_habtm_finder+'.find(:all, pagination_and_conditions.dup)') #attention! .dup to avoid :readonly => true ??
      else
        @targets = target_model.ar_finder_scope.ar_pagination_scope.all(opts)
        @count = target_model.ar_finder_scope.count
      end
    end

    #
    # loop parameters trying to guess polymorphic fields to setup
    #
    def prepare_polymorphic_association
      params.each do |p|
        if p[0].match(/.*_id$/)
          lookup_for_polymorphic_association(p) { |param_id|
            params[target_model_to_underscore][ActiveRest::Helpers::Routes::Mapper::POLYMORPHIC[target_model.to_s][:foreign_type]] = ActiveRest::Helpers::Routes::Mapper::AS[param_id][:map_to_model]
            params[target_model_to_underscore][ActiveRest::Helpers::Routes::Mapper::AS[param_id][:map_to_primary_key]] = p[1]
          }
        end
      end
    end

    #
    # avoid any action that can modify the record or change the table
    #
    def check_read_only
      generic_rescue_action(:method_not_allowed) if target_model_read_only
    end


    #
    # parse join if controller declared the option :join => ...
    #
    # there are these cases:
    #
    # 1) :join => { :genus => [:name] }
    # this tell to join the class genus and return only the field name
    #
    # 2) :join => { :assoc => true }
    # associa tutti i campi, rimappa i nomi come #{table_name}_#{column_name}
    #
    # 3) :join => { :assoc => [:colonna1, :colonna2....] }
    # associa i campi specificati, rimappa i nomi come #{table_name}_#{column_name}
    #
    # 4) :join => { :assoc => { :colonna1 => 'nome1', :colonna2 => 'nome2',.... } }
    # associa i campi specificati, usa i nomi specificati
    #
    def parse_joins
      join_options = model_options.has_key?(:join) ? model_options[:join] : {}

      # any unknown reflection will be ignored
      joins = join_options.keys.select do | j |
        join_options[j] && target_model.reflections.has_key?(j.to_sym)
      end if join_options

      parsed = {}

      joins.each do | reflection_key |
        fields = []
        join = join_options[reflection_key].is_a?(Symbol) || join_options[reflection_key].is_a?(String) ? [join_options[reflection_key]] : join_options[reflection_key]

        table_name = target_model.reflections[reflection_key].class_name.constantize.table_name
        quoted_table_name = target_model.connection.quote_table_name(table_name)

        #puts "JOIN OPTIONS  --> #{join.inspect}"
        if join.is_a?(Array)
          #
          # { :users => [:name] }
          #
          join.each do | f |
              parsed["#{quoted_table_name}.#{target_model.connection.quote_column_name(f.to_s)}"] = target_model.connection.quote_column_name("#{reflection_key.to_s}_#{f.to_s}")
          end
        elsif join.is_a?(Hash) && !join.empty?
          #
          # { :users => { :name => 'user_name' } } # this permit field name rewriting
          #
          join.each do | f, f1 |
              parsed["#{quoted_table_name}.#{target_model.connection.quote_column_name(f.to_s)}"] = target_model.connection.quote_column_name(f1.to_s)
          end
        else
          #
          # { :crap => true, :contacts => true }  # ex. crap does not exist and has been ignored
          # { :users => [:name], :contacts => true } # array
          # { :users => :name, :contacts => true } # string
          #
          target_model.reflections[reflection_key].klass.column_names.each do | f |
              parsed["#{quoted_table_name}.#{target_model.connection.quote_column_name(f.to_s)}"] = target_model.connection.quote_column_name("#{reflection_key.to_s}_#{f.to_s}")
          end
        end
      end

      return [joins, parsed]
    end

    def build_joins
      joins, select = parse_joins

      select = select.collect do | a, b |
        "#{a} AS #{b}"
      end

      select = "#{target_model.quoted_table_name}.*, #{ select.join(', ') }" unless select.nil? || select.empty?

      return [joins,select]
    end
  end

end
end
