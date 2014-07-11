
## Consul Mock-Up

require 'sinatra'
require 'json'

set :port, 8500

mock_data = JSON.parse '{"Node":{
            "Node":"consul-client","Address":"10.1.2.3"
        },"Services":{
            "service1":{"ID":"service1","Service":"service1","Tags":["web","s1"],"Port":80},
            "service2":{"ID":"service2","Service":"service2","Tags":["web","s2"],"Port":81}
        }
      }'

get '/v1/catalog/node/consul-client' do
  mock_data.to_json
end

get '/v1/health/node/consul-client' do
  '[{"Notes":"","ServiceName":"","Status":"passing","ServiceID":"","Output":"","CheckID":"serfHealth","Node":"consul-client","Name":"Serf Health Status"},{"Notes":"","ServiceName":"service1","Status":"passing","ServiceID":"service1","Output":"","CheckID":"service:service1","Node":"consul-client","Name":"Service \'service1\' check"},{"Notes":"","ServiceName":"service2","Status":"failing","ServiceID":"service2","Output":"","CheckID":"service:service2","Node":"consul-client","Name":"Service \'service2\' check"}]'
end

get '/v1/catalog/service/service1' do
  '[{"Node":"consul-client","Address":"10.1.2.3","ServiceID":"service1","ServiceName":"service1","ServiceTags":["web","s1"],"ServicePort":80}]'
end

get '/v1/catalog/service/service2' do
  '[{"Node":"consul-client","Address":"10.1.2.3","ServiceID":"service2","ServiceName":"service2","ServiceTags":["web","s2"],"ServicePort":81}]'
end

get '/mock-ready' do
  'ready'
end

get '/mock-end' do
  Kernel.exit!
end
