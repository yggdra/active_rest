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
# == Usage
#
#
#

module ActiveRest

  def self.included(base)
    base.extend(ClassMethods)

    base.class_eval do
      class_inheritable_accessor :target_model
      class_inheritable_accessor :target_model_read_only # check actions new, create, update, edit, delete, validate_*

      class_inheritable_accessor :index_options # options for index
      class_inheritable_accessor :extjs_options # options for ext js framework
      class_inheritable_accessor :model_options # model options

      class_inheritable_accessor :rest_xact_handler

      attr_accessor :target, :targets
    end
  end

  def rest_default_transaction_handler
    target_model.transaction do
      yield
    end
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
      #

      self.index_options = params[:index_options] || {}
      #
      # extjs_options ammitted key
      #
      self.extjs_options = params[:extjs_options] || {}

      #
      # options for model level
      # - join (an hash to build a custom select with join - see ActiveRest::Controller::Core.build_joins
      #
      self.model_options = params[:model_options] || {}

      self.rest_xact_handler = :rest_default_transaction_handler

      build_associations_proxies

      class_eval do
        # if read only not allow these actions
        before_filter :check_read_only, :only=> [ :new, :create, :update, :destroy, :validate_create, :validate_update ]

        # if we get here, chek for polymorphic associations
        before_filter :prepare_polymorphic_association, :only => :create

        before_filter :prepare_i18n
        before_filter :check_validation_action, :only => [ :update, :create ] # are we just requiring validations ?
        before_filter :find_target, :only => [ :show, :edit, :update, :destroy, :validate_update ] # 1 resource?
        before_filter :find_targets, :only => [ :index ] # find all resources ?
      end

      module_eval do
        include ActiveRest::Pagination # manage pagination
        include ActiveRest::Finder
        include ActiveRest::Controller::Core # common stuff
        include ActiveRest::Controller::Actions::Rest # default verbs and actions
        include ActiveRest::Controller::Actions::MembersRest # default verbs and actions
        include ActiveRest::Controller::Actions::Inspectors # extra default actions
        include ActiveRest::Controller::Actions::Validations # contains validation actions
      end
    end

    def rest_transaction_handler(method)
      self.rest_xact_handler = method
    end
  end
end # eo module
