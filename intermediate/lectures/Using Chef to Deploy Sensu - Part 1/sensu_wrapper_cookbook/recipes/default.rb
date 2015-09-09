# Server Stuff
include_recipe "sensu::default"
include_recipe "sensu::rabbitmq"
include_recipe "sensu::redis"
include_recipe "sensu::api_service"
include_recipe "sensu::server_service"
include_recipe "uchiwa"

# Handlers
sensu_gem 'sensu-plugins-mailer'
sensu_handler "mailer" do
  type "pipe"
  command "/opt/sensu/embedded/bin/handler-mailer.rb"
end
sensu_snippet 'mailer' do
  content(
  'admin_gui'    => 'http://localhost:3000/',
  'mail_from'    => 'sensu@localhost',
  'smtp_address' => 'localhost',
  'smtp_port'    => '25',
  'smtp_domain'  => 'localhost'
  )
end


# Client Stuff
sensu_client 'localhost' do
  address '127.0.0.1'
  subscriptions []
end
include_recipe "sensu::client_service"

# Standard Client Checks
sensu_gem 'sensu-plugins-disk-checks'
sensu_check 'check-disk' do
  command "/opt/sensu/embedded/bin/check-disk-usage.rb"
  standalone true
end
