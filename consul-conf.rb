
require 'json'
require 'curb'
require 'erubis'
require 'logger'

require_relative 'lib/ServiceBackends.rb'

$log = Logger.new STDERR
$log.level = Logger::DEBUG

begin
  config = JSON.parse File.read('config.json')
rescue JSON::ParserError => e
  $log.fatal "Failed to read JSON in config.json: #{e.message}"
  exit 1
end

backends = ServiceBackends.new config, $log

services = backends.allServiceBackends

$log.debug "After consulting consul, ended up with services like this:\n" <<
    JSON.pretty_generate(config['services'])

eruby = Erubis::Eruby.new(File.read config['template'])
puts eruby.result(:services => config['services'])

exit 0
