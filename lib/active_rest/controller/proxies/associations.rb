#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = ActiveRest::Controller::Proxies::Associations
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: associations.rb 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
#
#

module ActiveRest
module Controller
module Proxies

  module Associations

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      #
      # generates proxy methods for :has_one, :belongs_to model reflections
      # these methods do a redirect to a specific resource
      #
      def build_associations_proxies
        target_model.reflections.keys.each do | k |
          if target_model.reflections[k].macro == :has_one or target_model.reflections[k].macro == :belongs_to
            if ActiveRest::Controller.config.members_crud
              # crud for has_many and belongs_to
              line = __LINE__
              class_eval %{
                def #{target_model.reflections[k].name.to_s}
                  find_target(:return_object => true)
                  case (request.method)
                  when :get
                    @member = @target.send('#{target_model.reflections[k].name.to_s}'.to_sym)
                    return #{target_model.reflections[k].name.to_s}_show if respond_to?(:#{target_model.reflections[k].name.to_s}_show)
                    member_show(:#{target_model.reflections[k].macro}, '#{target_model.reflections[k].name}')
                  when :post
                    @member = #{target_model.reflections[k].class_name}.new
                    return #{target_model.reflections[k].name.to_s}_create if respond_to?(:#{target_model.reflections[k].name.to_s}_create)
                    member_create(:#{target_model.reflections[k].macro}, '#{target_model.reflections[k].name}')
                  when :put
                    @member = @target.send('#{target_model.reflections[k].name.to_s}'.to_sym)
                    return #{target_model.reflections[k].name.to_s}_update if respond_to?(:#{target_model.reflections[k].name.to_s}_update)
                    member_update(:#{target_model.reflections[k].macro}, '#{target_model.reflections[k].name}')
                  when :delete
                    @member = @target.send('#{target_model.reflections[k].name.to_s}'.to_sym)
                    return #{target_model.reflections[k].name.to_s}_delete if respond_to?(:#{target_model.reflections[k].name.to_s}_delete)
                    member_delete(:#{target_model.reflections[k].macro}, '#{target_model.reflections[k].name}')
                  end
                end
              }, __FILE__, line + 1

              unless respond_to?("#{target_model.reflections[k].name.to_s}_new".to_sym)
                line = __LINE__
                class_eval %{
                  def #{target_model.reflections[k].name.to_s}_new
                    find_target
                    @target
                    @member = #{target_model.reflections[k].class_name}.new
                    member_new(:#{target_model.reflections[k].macro}, '#{target_model.reflections[k].name}')
                  end
                }, __FILE__, line + 1
              end


              unless respond_to?("#{target_model.reflections[k].name.to_s}_edit".to_sym)
                line = __LINE__
                class_eval %{
                  def #{target_model.reflections[k].name.to_s}_edit
                    find_target
                    @target
                    @member = @target.send('#{target_model.reflections[k].name.to_s}'.to_sym)
                    member_edit(:#{target_model.reflections[k].macro}, '#{target_model.reflections[k].name}')
                  end
                }, __FILE__, line + 1
              end

            else
              # has_many and belongs_to redirects to member controller
              line = __LINE__
              class_eval %{
                def #{target_model.reflections[k].name.to_s}
                  find_target
                  res = @target['#{target_model.reflections[k].name.to_s}'.to_sym]
                  id = res[:id] if res

                  if id.nil?
                    generic_rescue_action(:not_found)
                    return
                  end

                  url = ActiveRest::Helpers::Routes::Mapper.url_for('#{target_model.reflections[k].name.to_s}') + '/' + id.to_s
                  url += '.'+params[:format] if params[:format]

                  redirect_to url
                end
              }, __FILE__, line + 1

            end
          end
        end
      end
    end
  end

end
end
end

ActionController::Base.send(:include, ActiveRest::Controller::Proxies::Associations) # generate specific actions for relations
