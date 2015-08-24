module AppDeployer
  class LoadBalancer
    include Core::DSL

    UPSTREAM_FILE = File.join(File.dirname(__FILE__), '../../data/nginx/upstream_file.conf.erb')

    attribute :location, default: :local
    attribute :upstream, required: true
    attribute :pid_file, default: '/var/run/nginx.pid', required: true

    def remote(hash)
      self.location = hash
    end

    def local
      self.location = :local
    end

    def update_upstream(servers)
      output = ERB.new(File.read(UPSTREAM_FILE), nil, '<>')
        .result(binding)
      file_name = File.join(upstream, "#{name}.conf")
      @connection.write_file(file_name: file_name, contents: output)
    end

    def reload
      @connection.kill(process_id: get_process_id, signal: 'HUP')
    end

    private

    attr_reader :connection

    def after_initialize
      if self.location == :local
        @connection = Core::Executor.local
      else
        @connection = Core::Executor.remote(ssh_config: self.location)
      end
    end

    def get_process_id
      @connection.print_file(file_name: pid_file).chomp
    end
  end
end
