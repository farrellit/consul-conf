
include_recipe 'apt'

r = group node[:consul_conf][:group]

r= user node[:consul_conf][:user]  do
  gid node[:consul_conf][:group] 
  home "/home/consul_conf"
  shell "/bin/bash"
  supports manage_home: true
end

%w(
  curl
  gawk libyaml-dev libsqlite3-dev sqlite3 autoconf 
  libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev
  libcurl4-openssl-dev
).each do |pkg|
  package pkg
end

bash "install rvm/ruby for user" do
  code '\curl -sSL https://get.rvm.io | bash -s stable --ruby=1.9.3 --autolibs=2'
  cwd "/home/consul_conf"
  user node[:consul_conf][:user]
  environment 'HOME'=>'/home/consul_conf'
  not_if "sudo -i -u #{node[:consul_conf][:user]} which consul-conf"
end

gemfile = ::File.join [ "/tmp", ::File.basename( URI.parse(node[:consul_conf][:gem_uri]).path ) ]

remote_file gemfile  do
    source node[:consul_conf][:gem_uri]
end

bash 'install gem for user' do
  code "sudo -i -u #{node[:consul_conf][:user]} gem install /tmp/consul-conf-0.1.0.gem"
end

file gemfile do
  action :delete
end
