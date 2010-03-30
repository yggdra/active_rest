#
# ActiveRest, a more powerful rest resources manager
# Copyright (C) 2008, Intercom s.r.l., windmillmedia
#
# = Rake Tasks
#
# Author:: Lele Forzani <lele@windmill.it>, Alfredo Cerutti <acerutti@intercom.it>
# License:: Proprietary
#
# Revision:: $Id: active_rest_tasks.rake 5105 2009-08-05 12:30:05Z dot79 $
#
# == Description
#
# 
# 

require 'pp'


namespace :active_rest do

  desc "detect and print the has_many through relations found in this application"
  task :list_through => :environment do
    puts '-'*80
    puts 'HAS MANY THROUGH'
    puts '-'*80    
    pp ActiveRest::Helpers::Routes::Mapper::THROUGH   
  end
  
  desc "detect and print the polymorphic relations found in this application"
  task :list_polymorphic => :environment do  
    puts '-'*80
    puts 'POLYMORPHIC'
    puts '-'*80
    pp ActiveRest::Helpers::Routes::Mapper::POLYMORPHIC
    
    
    puts '-'*80
    puts 'AS'
    puts '-'*80
    pp ActiveRest::Helpers::Routes::Mapper::AS
  end
  
end