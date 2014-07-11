
require 'json'
require 'logger'
require 'curb'

require_relative "../lib/consul-conf/ServiceBackends.rb"

### Start up webserver and wait for it to be ready

require_relative './include-mock.rb'

### Run Tests

config = JSON.parse( File.read "config.json" )
log = Logger.new STDOUT
log.level = Logger::DEBUG

$sb = nil

describe ConsulConf::ServiceBackends do
    it 'should initialize with config and log' do
        $sb = ConsulConf::ServiceBackends.new config, log
    end
    it 'should raise ConsulConf::ServiceBackends::RestException on bad url' do
        expect{ $sb.getUrl '/bad/url' }.to raise_error( ConsulConf::ServiceBackends::RestException )
    end
    it 'should return array from health check url' do
        res = $sb.getUrl '/v1/health/node/consul-client' 
        expect(res).to be_kind_of Array
    end

    it 'should return mocked health checks from getHealthChecks' do
        res = $sb.getHealthChecks "consul-client","service1" 
        expect(res).to eq([{ 'Notes' => '', 'ServiceName' => '', 'Status' => 'passing', 'ServiceID' => '', 'Output' => '', 'CheckID' => 'serfHealth', 'Node' => 'consul-client', 'Name' => 'Serf Health Status' }, { 'Notes' => '', 'ServiceName' => 'service1', 'Status' => 'passing', 'ServiceID' => 'service1', 'Output' => '', 'CheckID' => 'service:service1', 'Node' => 'consul-client', 'Name' => "Service 'service1' check" }])
        res = $sb.getHealthChecks "consul-client","service2" 
        expect(res).to eq([{ 'Notes' => '', 'ServiceName' => '', 'Status' => 'passing', 'ServiceID' => '', 'Output' => '', 'CheckID' => 'serfHealth', 'Node' => 'consul-client', 'Name' => 'Serf Health Status' }, { 'Notes' => '', 'ServiceName' => 'service2', 'Status' => 'failing', 'ServiceID' => 'service2', 'Output' => '', 'CheckID' => 'service:service2', 'Node' => 'consul-client', 'Name' => "Service 'service2' check" }])
    end    
    
    it 'should return true on healthy service from getServiceHealth' do
        expect( $sb.getServiceHealth 'consul-client', 'service1' ).to eq(true )
    end

    it 'should return false on unhealthy service from getServiceHealth' do
        expect( $sb.getServiceHealth 'consul-client', 'service2' ).to eq(false )
    end

    it 'should return expected node from getServiceNodes for healthy service' do
        expect( $sb.getServiceNodes 'service1' ).to eq([{ 'name' => 'consul-client', 'ip' => '10.1.2.3', 'port' => 80, 'status' => 'up', 'health_checks' => [{ 'Notes' => '', 'ServiceName' => '', 'Status' => 'passing', 'ServiceID' => '', 'Output' => '', 'CheckID' => 'serfHealth', 'Node' => 'consul-client', 'Name' => 'Serf Health Status' }, { 'Notes' => '', 'ServiceName' => 'service1', 'Status' => 'passing', 'ServiceID' => 'service1', 'Output' => '', 'CheckID' => 'service:service1', 'Node' => 'consul-client', 'Name' => "Service 'service1' check" }]}])
    end
    
    it 'should return expected node from getServiceNodes for unhealthy service' do
        expect( $sb.getServiceNodes 'service2' ).to eq([{ 'name' => 'consul-client', 'ip' => '10.1.2.3', 'port' => 81, 'status' => 'down', 'health_checks' => [{ 'Notes' => '', 'ServiceName' => '', 'Status' => 'passing', 'ServiceID' => '', 'Output' => '', 'CheckID' => 'serfHealth', 'Node' => 'consul-client', 'Name' => 'Serf Health Status' }, { 'Notes' => '', 'ServiceName' => 'service2', 'Status' => 'failing', 'ServiceID' => 'service2', 'Output' => '', 'CheckID' => 'service:service2', 'Node' => 'consul-client', 'Name' => "Service 'service2' check" }]}])
    end

    it 'should return all services from allServiceBackends' do 
        expect( $sb.allServiceBackends ).to eq([{ 'name' => 'service1', 'port' => 8080, 'cookie' => true, 'check' => 'inter 3000 rise 2 fall 3 maxconn 255', 'options' => ['httpchk GET /ping'], 'servers' => [{ 'name' => 'consul-client', 'ip' => '10.1.2.3', 'port' => 80, 'status' => 'up', 'health_checks' => [{ 'Notes' => '', 'ServiceName' => '', 'Status' => 'passing', 'ServiceID' => '', 'Output' => '', 'CheckID' => 'serfHealth', 'Node' => 'consul-client', 'Name' => 'Serf Health Status' }, { 'Notes' => '', 'ServiceName' => 'service1', 'Status' => 'passing', 'ServiceID' => 'service1', 'Output' => '', 'CheckID' => 'service:service1', 'Node' => 'consul-client', 'Name' => "Service 'service1' check" }]}]}, { 'name' => 'service2', 'port' => 8081, 'cookie' => false, 'check' => 'inter 3000 rise 2 fall 3 maxconn 255', 'options' => ['httpchk GET /ping'], 'servers' => [{ 'name' => 'consul-client', 'ip' => '10.1.2.3', 'port' => 81, 'status' => 'down', 'health_checks' => [{ 'Notes' => '', 'ServiceName' => '', 'Status' => 'passing', 'ServiceID' => '', 'Output' => '', 'CheckID' => 'serfHealth', 'Node' => 'consul-client', 'Name' => 'Serf Health Status' }, { 'Notes' => '', 'ServiceName' => 'service2', 'Status' => 'failing', 'ServiceID' => 'service2', 'Output' => '', 'CheckID' => 'service:service2', 'Node' => 'consul-client', 'Name' => "Service 'service2' check" }]}]}])
    end
    
    it 'should return all up ervers from allServiceBackends(true)' do 
        expect( $sb.allServiceBackends true ).to eq([{ 'name' =>  'service1', 'port' =>  8080, 'cookie' =>  true, 'check' =>  'inter 3000 rise 2 fall 3 maxconn 255', 'options' =>  ['httpchk GET /ping'], 'servers' =>  [{ 'name' =>  'consul-client', 'ip' =>  '10.1.2.3', 'port' =>  80, 'status' =>  'up', 'health_checks' =>  [{ 'Notes' =>  '', 'ServiceName' =>  '', 'Status' =>  'passing', 'ServiceID' =>  '', 'Output' =>  '', 'CheckID' =>  'serfHealth', 'Node' =>  'consul-client', 'Name' =>  'Serf Health Status' }, { 'Notes' =>  '', 'ServiceName' =>  'service1', 'Status' =>  'passing', 'ServiceID' =>  'service1', 'Output' =>  '', 'CheckID' =>  'service:service1', 'Node' =>  'consul-client', 'Name' =>  "Service 'service1' check" }]}]}, { 'name' =>  'service2', 'port' =>  8081, 'cookie' =>  false, 'check' =>  'inter 3000 rise 2 fall 3 maxconn 255', 'options' =>  ['httpchk GET /ping'], 'servers' =>  []}])
    end

end


