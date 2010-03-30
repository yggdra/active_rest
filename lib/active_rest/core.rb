#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# =
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: base.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest

  module Core
    def self.included(base)
      base.class_eval do
        class_inheritable_accessor :target_model
        class_inheritable_accessor :target_model_read_only # check actions new, create, update, edit, delete, validate_*

        class_inheritable_accessor :index_options # options for index
        class_inheritable_accessor :extjs_options # options for ext js framework
        class_inheritable_accessor :model_options # model options

        attr_accessor :target, :targets

      end
      base.extend(ClassMethods)
    end

    module ClassMethods

      #
      # bind a controller-model
      #
      def rest_controller_for(model, params={})
        self.target_model = model
        self.target_model_read_only = params[:read_only] || false

        #
        # index_options ammitted key
        # - extra_conditions (a controller def method)
        # - finder (a symbol rappresenting the plugin/finder or a custom Module declared in app project)
        #
        self.index_options = params[:index_options] || {}

        #
        # extjs_options ammitted key
        # - standard_submit (boolean)
        # - standard_error (boolean)
        # - standard_crud (boolean)
        #
        self.extjs_options = params[:extjs_options] || {}

        if self.extjs_options[:stardard_submit].nil?
          self.extjs_options[:stardard_submit] = ActiveRest::Configuration[:extjs_stardard_submit].nil? ?
                                                   false :
                                                   ActiveRest::Configuration[:extjs_stardard_submit]
        end

        if self.extjs_options[:standard_error].nil?
          self.extjs_options[:standard_error] = ActiveRest::Configuration[:extjs_standard_error].nil? ?
                                                  false :
                                                  ActiveRest::Configuration[:extjs_standard_error]
        end

        if self.extjs_options[:standard_crud].nil?
          self.extjs_options[:standard_crud] = ActiveRest::Configuration[:extjs_standard_crud].nil? ?
                                                 false :
                                                 ActiveRest::Configuration[:extjs_standard_crud]
        end

        #
        # options for model level
        # - join (an hash to build a custom select with join - see ActiveRest::Controller::Core.build_joins
        #
        self.model_options = params[:model_options] || {}

        build_associations_proxies

        class_eval do
          # if read only not allow these actions
          before_filter :check_read_only, :only=> [:new, :create, :update, :destroy, :validate_create, :validate_update]

          # you can override of this function and prevent access to the resources
          before_filter :active_rest_authorization

          # if we get here, chek for polymorphic associations
          before_filter :prepare_polymorphic_association, :only => :create

          before_filter :prepare_i18n
          before_filter :check_validation_action, :only => [ :update, :create ] # are we just requiring validations ?
          before_filter :find_target, :only => [ :show, :edit, :update, :destroy, :validate_update ] # 1 resource?
          before_filter :find_targets, :only => [ :index ] # find all resources ?
        end

        module_eval do
          include ActiveRest::Helpers::Pagination::Core # manage pagination - will load up the finder plugin
          include ActiveRest::Controller::Core # common stuff
          include ActiveRest::Controller::Actions::Rest # default verbs and actions
          include ActiveRest::Controller::Actions::MembersRest # default verbs and actions
          include ActiveRest::Controller::Actions::Inspectors # extra default actions
          include ActiveRest::Controller::Actions::Validations # contains validation actions
        end
      end
    end

  end # eo module
end # eo module

ActionController::Base.send(:include, ActiveRest::Core)
