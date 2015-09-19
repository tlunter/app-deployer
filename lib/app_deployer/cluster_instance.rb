module AppDeployer
  class ClusterInstance
    include Core::DSL

    attribute :ip, required: true
    attribute :location, default: :local
    attribute :options, default: {}

    def remote(url:)
      self.location = url
    end

    def local
      self.location = :local
      self.ip ||= '127.0.0.1'
    end

    def running_container_count
      containers.count
    end

    def containers
      Docker::Container.all({}, docker_connection)
    end

    def start_container(container, number, version)
      docker_container = Docker::Container.create(
        container.to_container_create_opts(number, version),
        docker_connection
      )
      docker_container.start
    end

    def find_load_balancer_containers(lb_container_names, version)
      lb_containers = containers.select do |container|
        labels = container.info['Labels']
        next unless labels[Container::DEPLOYER_LABEL]

        lb_container_names.any? do |lb_container_name|
          labels[Container::NAME_LABEL].to_s.start_with?(lb_container_name) && \
          labels[Container::VERSION_LABEL].to_s == version
        end
      end

      lb_containers.map do |container|
        { cluster_instance: self, container: container }
      end
    end

    def test_connectivity
      begin
        Docker.version(docker_connection)
        true
      rescue Excon::Errors::Error, Docker::Error::DockerError
        false
      end
    end

    def run_live_check(cmd)
      shell_connection.run(cmd) == 0
    end

    private

    attr_reader :docker_connection, :shell_connection

    def after_initialize
      if location == :local
        @docker_connection = Docker::Connection.new(Docker.url, Docker.options)
        if ip == '127.0.0.1'
          @shell_connection = Core::Executor.local
        else
          @shell_connection = Core::Executor.remote(ssh_config: { host: ip })
        end
      else
        opts = options.dup || {}
        if cert_path = opts[:cert_path]
          opts.merge!(
            client_cert: File.join(cert_path, 'cert.pem'),
            client_key: File.join(cert_path, 'key.pem'),
            ssl_ca_file: File.join(cert_path, 'ca.pem'),
            scheme: 'https'
          )
        end

        @docker_connection = Docker::Connection.new(
          location,
          opts
        )
        @shell_connection = Core::Executor.remote(ssh_config: { host: ip })
      end
    end
  end
end
