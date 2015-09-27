#!/opt/sensu/embedded/bin/ruby
require 'sensu-handler'

class Show < Sensu::Handler

  def handle
    response = NMA.notify do |n|
      n.apikey = settings["notify_my_android"]["api_key"]
      n.priority = NMA::Priority::MODERATE
      n.application = "Sensu"
      n.event = @event['client']['name'] + '/' + @event['check']['name']
      n.description = event_summary
    end
    puts response.inspect
  end

end
