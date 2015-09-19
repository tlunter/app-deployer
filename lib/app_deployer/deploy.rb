module AppDeployer
  class Deploy
    include Core::DSL

    attribute :live_check, default: Proc.new { |host, port| ['true'] }
    attribute :s3_location
    class_attribute :load_balancer
    class_attribute :application

    def start_application(version)
      application.start(version)
    end

    def destroy_old_application(version)
      application.destroy_old(version)
    end

    def assign_app_ports_to_load_balancer(version)
      servers = application.find_load_balancer_ports(version)
      load_balancer.update_upstream(servers)
    end

    def reload_load_balancer
      load_balancer.reload
    end

    def validate_application_live(version)
      servers = application.find_load_balancer_instances(version)
      $stderr.puts "Starting with: #{servers}"
      loop do
        break if servers.empty?

        $stderr.puts "Remaining servers: #{servers}"
        servers.each do |pair|
          cluster_instance = pair[:cluster_instance]
          port = pair[:port]

          cmd = live_check.call(cluster_instance.ip, port)

          if cluster_instance.run_live_check(cmd)
            servers.delete(pair)
            $stderr.puts "Deleting pair: #{pair}"
          end
        end
      end
    end
  end
end
