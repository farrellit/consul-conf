
require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe "gem install under user" do
  describe command("sudo -i -u consul_conf consul-conf ") do
    it { should return_stdout /Usage: .*consul-conf configfile/ }
    it { should return_exit_status 1 }
  end
end

