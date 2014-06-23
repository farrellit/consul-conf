
require 'json'
require 'curb'
require 'logger'

class ServiceBackends

    class RestException < Exception
        def initialize msg=""
            if msg
                msg = ": #{msg}"
            end
            super "Consul REST Exception#{msg}"
        end
    end

    def initialize config, log
        @curler = Curl::Easy.new
        @log = log
        @config = config
        @node_healths = {}
        @base_url = "http://#{config['consul']['host']}:#{config['consul']['port']}"
    end

    def getUrl path
        path = "/path" unless path[0] == "/"
        @curler.url = "#{@base_url}#{path}"
        @log.debug "Pulling #{@curler.url}"
        begin
            unless @curler.perform 
                raise RestException.new "Failed to perform Curl for #{ @curler.url }"
            end
            JSON.parse @curler.body_str
        rescue Curl::Err::ConnectionFailedError => e
            raise RestException.new "Couldn't connect to #{@curler.url}: #{e.message}"
        rescue JSON::ParserError => e
            raise RestException.new "Couldn't parse JSON from #{ @curler.url}.  Response : #{ @curler.body_str.inspect }"
        end
    end

    def getHealthChecks node, service
        unless @node_healths.has_key? node
            @node_healths[node] = getUrl "/v1/health/node/#{node}"
        end
        @node_healths[node].select{ |check|
            check["ServiceName"] == service || check["CheckID"] == 'serfHealth'
        }
    end
    
    def passingStatus? check 
        if check.kind_of? Hash
            status = check['Status']
            @log.debug "Check status of #{check['CheckID']} is #{status}"
        else
            status = check
            @log.debug "Check status of (unspecified chekck) is #{status}"
        end
        status == "passing"
    end

    def getServiceHealth node,service
        serf_health = false
        service_health = true
        getHealthChecks(node,service).each{ |check|
            if check["CheckID"] == 'serfHealth'
                serf_health = passingStatus? check
            else
                service_health = ( service_health and passingStatus?( check ) )
            end
        }
        @log.debug "Combined service #{service} health is #{service_health}, serf health is #{serf_health}"
        serf_health and service_health
    end

    def getServiceNodes service
        nodes = getUrl "/v1/catalog/service/#{service}"
        servers = []
        nodes.each do |node|
            
            if getServiceHealth node['Node'], service
                status = 'up'
            else
                status = 'down'
            end
            servers << { 
                "name" => node["Node"],
                "ip" => node["Address"], 
                "port" => node["ServicePort"],
                "status" => status,
                "health_checks" => getHealthChecks(node["Node"], service)
            }
        end
        servers
    end

    def allServiceBackends onlypassing = false
        services = @config['services']
        services.each do |service|
            service['servers'] = getServiceNodes service['name']
            if onlypassing
                service['servers'].select! { |server|
                    server['status'] == 'up'
                }
            end
        end
        services
    end

end

