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
    end

    def running_container_count
      containers.count
    end

    def containers
      Docker::Container.all({}, connection)
    end

    def start_container(container, number)
      docker_container = Docker::Container.create(
        container.to_container_create_opts(number),
        connection
      )
      docker_container.start
    end

    def find_load_balancer_containers(lb_container_names)
      lb_containers = containers.select do |container|
        labels = container.info['Labels']
        next unless labels['com.tlunter.app-deployer']

        lb_container_names.any? do |lb_container_name|
          labels['com.tlunter.app-deployer.name'].to_s.start_with?(lb_container_name)
        end
      end

      lb_containers.flat_map do |container|
        container.info['Ports'].map do |port|
          { host: ip, port: port['PublicPort'] }
        end.compact
      end
    end

    def test_connectivity
      begin
        Docker.version(connection)
        true
      rescue Excon::Errors::Error, Docker::Error::DockerError
        false
      end
    end

    private

    attr_reader :connection

    def after_initialize
      if location == :local
        @connection = Docker::Connection.new(Docker.url, Docker.options)
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

        @connection = Docker::Connection.new(
          location,
          opts
        )
      end
    end
  end
end
