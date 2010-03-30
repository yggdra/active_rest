ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/environment')
require 'spec'
require 'spec/rails'


db_file = File.dirname(__FILE__) +'/active_rest.db'
File.delete(db_file) if File.exist?(db_file)

I18n.backend = I18n::Backend::Simple.new

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'active_rest_sanbbox_db'])
load(File.dirname(__FILE__) + '/schema.rb') if File.exist?(File.dirname(__FILE__) + '/schema.rb')

require File.expand_path(File.dirname(__FILE__)+ '/models/company')
require File.expand_path(File.dirname(__FILE__)+ '/models/company_protected')
require File.expand_path(File.dirname(__FILE__)+ '/models/user')
require File.expand_path(File.dirname(__FILE__)+ '/models/contact')
require File.expand_path(File.dirname(__FILE__)+ '/models/user_virtual_attrs')

routes = File.join(RAILS_ROOT, 'vendor', 'plugins', 'active_rest', 'spec', 'routes.rb')
ActionController::Routing::Routes.add_configuration_file(routes)
ActionController::Routing::Routes.reload!


Spec::Runner::configure do |config|
  config.fixture_path = File.expand_path(File.dirname(__FILE__)  + '/fixtures/')
end

STATUS = {
  :s201 => '201 Created',
  :s202 => '202 Accepted',
  :s400 => '400 Bad Request',
  :s403 => '403 Forbidden',
  :s404 => '404 Not Found',
  :s405 => '405 Method Not Allowed',
  :s406 => '406 Not Acceptable'
}
