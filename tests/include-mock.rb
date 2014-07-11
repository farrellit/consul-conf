
### Start up webserver and wait for it to be ready

websvr_pid = fork do
  system(' ruby ./consul-mock.rb')
end

puts "Webserver should start on #{websvr_pid}"

chk = Curl::Easy.new
chk.url = 'http://localhost:8500/mock-ready'
class WaitException < Exception
end
begin
  Process.kill(0, websvr_pid)
  chk.perform
  fail WaitException.new 'Still waiting' unless chk.body_str == 'ready'
rescue Curl::Err::ConnectionFailedError
  if Process.wait(websvr_pid, Process::WNOHANG) == websvr_pid
    puts 'Webserver app has failed to execute.'
    exit 1
  end
  sleep 0.2
  retry
rescue WaitException => e
  puts "Didn't get ready response"
  sleep 0.2
  retry
rescue Errno::ESRCH => e
  $stderr.puts 'PID not found: webserver startup failed'
  exit 1
end

### Cleanup webserver thread at exit

Kernel.at_exit do
  chk.url = 'http://localhost:8500/mock-end'
  begin
    chk.perform
rescue => e
  end
  Process.wait websvr_pid
end
