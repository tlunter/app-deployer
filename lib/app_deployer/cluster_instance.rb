module AppDeployer
  class ClusterInstance
    include Core::DSL

    attribute :location, default: :local
    attribute :options, default: {}

    def remote(url:)
      self.location = url
    end

    def local
      self.location = :local
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
        @connection = Docker::Connection.new
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
