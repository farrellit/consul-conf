Gem::Specification.new do |s|
  s.name        = 'consul-conf'
  s.version     = '0.1.0'
  s.date        = '2014-07-11'
  s.summary     = 'generate config files from consul discovered nodes and specified services'
  s.description = 'Use the consul REST API to query node status for specified services, \
    then pass this data to a template and handle writing out \
    a new config file, if updates are required.'
  s.authors     = ['Dan Farrell']
  s.email       = 'dfarrell@bloomhealthco.com'
  s.files       = ['lib/consul-conf.rb', 'lib/consul-conf/ServiceBackends.rb']
  s.homepage    = 'http://github.com/dfarrell-bloom/consul-conf'
  s.license       = 'MIT'

  s.add_runtime_dependency 'curb', '~>0.8', '>= 0.8.5'
  s.add_runtime_dependency 'erubis', '~>2.7', '>= 2.7.0'

  s.add_development_dependency 'sinatra', '~> 1.4', '>= 1.4.4'
  s.add_development_dependency 'rake', '~> 10.3', '>=10.3.2'
  s.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.1'
  s.add_development_dependency 'rubocop', '~> 0.24', '>= 0.24.1'
end
