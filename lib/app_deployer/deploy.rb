module AppDeployer
  class Deploy
    include Core::DSL

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
  end
end
