module AppDeployer
  class Deploy
    include Core::DSL

    attribute :s3_location
    class_attribute :load_balancer
    class_attribute :application

    def start_application(version)
      application.start(version)
    end

    def assign_app_ports_to_load_balancer
      servers = application.find_load_balancer_ports
      load_balancer.update_upstream(servers)
    end

    def reload_load_balancer
      load_balancer.reload
    end
  end
end
