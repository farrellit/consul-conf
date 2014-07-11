
require_relative '../lib/consul-conf.rb'

### Start up webserver and wait for it to be ready

require_relative './include-mock.rb'

require 'tempfile'
require 'json'

def cleanup
  %w(output.txt output.txt.copy).each do |f|
    File.unlink(f) if File.exist? f
  end
end

# cleanup at end of run
Kernel.at_exit do
  cleanup
end

### Run Tests

$log = Logger.new $STDERR
$log.level = Logger::DEBUG
$tmpconfig = Tempfile.new 'tmpconfig'
# $tmpconfig = File.open "/tmp/config", "w+"

def valid_config
  JSON.parse File.read('config.json')
end

class ATime
  @@time = nil
  def initialize
    @@time = Time.new unless @@time
  end

  def to_s
    @@time.to_s
  end
end

def expected_rendering(input = nil)
  input = ATime.new unless input
  return <<-eof
# This is a test template to check rendering generated #{input}

listen service1 0.0.0.0:8080
  cookie service1_svr insert indirect nocache
  option httpchk GET /ping
  server consul-client 10.1.2.3:80  cookie consul-client  check inter 3000 rise 2 fall 3 maxconn 255 
  # Check ID serfHealth, "Serf Health Status", status: passing
  # Check ID service:service1, "Service 'service1' check", status: passing
listen service2 0.0.0.0:8081
  option httpchk GET /ping
  server consul-client 10.1.2.3:81  check inter 3000 rise 2 fall 3 maxconn 255 
  # Check ID serfHealth, "Serf Health Status", status: passing
  # Check ID service:service2, "Service 'service2' check", status: failing
eof
end

def rewrite(tmpfile, data)
  tmpfile.truncate 0
  tmpfile.rewind
  tmpfile.write ( [Hash, Array].include?(data.class) ? data.to_json : data)
  tmpfile.fsync
  tmpfile.rewind
end

describe ConsulConf do
  it 'should raise expected errors on bad invocation' do
    expect { ConsulConf.new 'log', nil }.to raise_error ConsulConf::InitError
    expect { ConsulConf.new $log, '' }.to raise_error ConsulConf::InitError
    $tmpconfig.write 'This is not valid json'
    expect { ConsulConf.new $log, $tmpconfig.path }.to raise_error ConsulConf::InitError
    rewrite $tmpconfig,  this: 'is valid json, but not the expected json',
                         these: %w(are an array of words)
    expect { ConsulConf.new $log, $tmpconfig.path }.to raise_error ConsulConf::ConfigError
  end

  it 'should error about missing config file sections' do
    config = valid_config
    %w(template outfile).each do |sect|
      config.delete sect
    end
    rewrite $tmpconfig, config
    expect { ConsulConf.new $log, $tmpconfig }.to raise_error ConsulConf::ConfigError
  end

  [-1, 256, 1000, -1000, -256, -255].each do |status|
    it 'should warn on invalid postupdate_status' do
      config = valid_config
      config['postupdate_status'] = status
      rewrite $tmpconfig, config
      expect($log).to receive('warn').with("Configuration option 'postupdate_status' out of range ( exit status is 8 bit unsigned integer ).  #{status} will never be an exit status")
      ConsulConf.new $log, $tmpconfig
    end
  end

  it "should set a default postupdate_status if one isn't set" do
    config = valid_config
    config.delete 'postupdate_status'
    rewrite $tmpconfig, config
    cc = ConsulConf.new $log, $tmpconfig
    expect(cc.config['postupdate_status']).to eq(0)
  end

  cc = nil
  it 'should initialize successfully with a proper config file' do
    cc = ConsulConf.new $log, 'config.json'
  end

  it 'should properly load a regex for the comment_regex' do
    expect(cc.config['comment_regex']).to be_kind_of Regexp
  end

  it 'should identify existing and nonexisting config sections as such' do
    expect(cc.checkConfigOption 'template').to eq(true)
    expect(cc.checkConfigOption 'nonexistant_config_option').to eq(false)
  end

  it 'should correctly render' do
    expect(cc.render).to eq(expected_rendering)
  end

  it 'should properly remove comments' do
    expect(cc.remove_comments expected_rendering).to eq("
listen service1 0.0.0.0:8080
  cookie service1_svr insert indirect nocache
  option httpchk GET /ping
  server consul-client 10.1.2.3:80  cookie consul-client  check inter 3000 rise 2 fall 3 maxconn 255 
listen service2 0.0.0.0:8081
  option httpchk GET /ping
  server consul-client 10.1.2.3:81  check inter 3000 rise 2 fall 3 maxconn 255 \n")
  end

  it 'should successfully diff equal files' do
    f1 = Tempfile.new 'f1'
    f2 = Tempfile.new 'f2'
    [f1, f2].each do |f|
      rewrite f, 'This is a bunch of content that is the same.  '
    end
    expect(cc.diff(f1.path, f2.path)).to eq(false)
  end

  it 'should successfully diff unequal files' do
    f1 = File.open('f1', 'w+')
    f2 = File.open('f2', 'w+')
    rewrite f1, "This is a bunch of content that is not the same.  #{rand}"
    rewrite f2, "This is a bunch of content that is not the same.  #{rand}"
    expect(f2.read == f2.read).to eq(false)
    expect($log).to receive('debug').with('Executing diff command: diff f1 f2')
    expect(cc.diff(f1.path, f2.path)).to eq(true)
    [f1, f2].each do |f|
      f.close
      File.unlink(f.path)
    end
  end

  it 'should warn on a failed diff ( ie due to missing file )' do
    expect($log).to receive('error').with('Diff appears to have failed: unexpected return status 2(it is assumed that the files are different)')
    expect(cc.diff('/tmp/noexist1', '/tmp/noexist2')).to eq(true)
  end

  it "should write out file if one doesn't exist" do
    cleanup
    cc.update
    expect(File.exist? cc.config['outfile']).to eq(true)
    expect(expected_rendering).to eq(File.read cc.config['outfile'])
  end

  it 'should identify equal content as not outdated' do
    expect(cc.outdated? File.read(cc.config['outfile'])).to eq(false)
  end

  it 'should identify equal content with different comments as not outdated' do
    expect(cc.outdated? expected_rendering('This is not the date we wrote out!')).to eq(false)
  end

  it 'should identify out of date content as such'  do
    expect(cc.outdated? expected_rendering + "\nnThese are brand new lines!").to eq(true)
  end

  it 'should properly run postupdate command with the postupdate function' do
    expect(cc.postupdate).to eq(true)
    expect(File.exist? "#{cc.config['outfile']}.copy").to eq(true)
  end

  it 'should log an error and update should return false if the postupdate status is not expected' do
    config = valid_config
    config['postupdate'] = 'false'  ## that is, the false command
    rewrite $tmpconfig, config
    cc2 = ConsulConf.new($log, $tmpconfig.path)
    expect($log).to receive(:error).with('Postupdate command appears to have failed.  Exit status expected: 0, got: 1')
    expect(cc2.postupdate).to eq(false)
  end

  it 'should properly update a config file without a postupdate' do
    config = valid_config
    config.delete 'postupdate'
    rewrite $tmpconfig, config
    cc2 = ConsulConf.new($log, $tmpconfig.path)
    cleanup
    expect(cc2.update).to eq(true)
    expect(File.exist? config['outfile']).to eq(true)
  end

  it 'should properly update an outdated config file and run postupdate' do
    cleanup
    expect(cc.update).to eq(true)
    expect(File.exist? cc.config['outfile']).to eq(true)
    expect(File.exist? "#{cc.config['outfile']}.copy").to eq(true)
  end

  it 'should properly not update an up-to-date config file and not run postupdate'  do
    File.unlink "#{cc.config['outfile']}.copy"
    expect(cc.update).to eq(true)
    expect(File.exist? cc.config['outfile']).to eq(true)
    expect(File.exist? "#{cc.config['outfile']}.copy").to eq(false)
  end

end
