
task :test do 
    Dir.chdir "tests" do
        specs = %w{ ServiceBackends ConsulConf }.each do |c|
            sh "rspec #{c}.rspec.rb"
        end
        puts  "\033[0;1;32m" << "All tests passing!  " << "\033[0m" << "Specs: \n#{ specs.map { |spec| " \033[0;33m*\033[0m tests/#{spec}.rspec"}.join "\n" }"
    end
end


require 'rubocop/rake_task'
RuboCop::RakeTask.new

