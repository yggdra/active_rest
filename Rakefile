require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'active_rest'
    gem.summary = %Q{REST controller mixin}
    gem.description = %Q{ActiveRest provides several useful actions for restful controllers}
    gem.email = 'daniele@orlandi.com'
    gem.homepage = 'http://www.yggdra.it/'
    gem.authors = ['vihai']
    gem.files = FileList['[A-Z]*.*', '{lib,spec,config,workers}/**/*']
    gem.test_files = FileList['specapp/**/*', ].exclude('specapp/log/**').exclude('specapp/db/*.sqlite3')
#    gem.add_development_dependency 'rspec', '>= 1.2.9'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

require 'rdoc/task'
desc 'Generate documentation for the rest_controller plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = "ActiveRest #{version}"
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

