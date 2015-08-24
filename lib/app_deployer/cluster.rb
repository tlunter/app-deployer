module AppDeployer
  class Cluster
    include Core::DSL

    class_attribute :cluster_instances, type: :collection

    def test_connectivity
      cluster_instances.reduce(true) do |memo, ci|
        memo &&= ci.test_connectivity
      end
    end

    def least_used_instance
      cluster_instances.min_by { |ci| ci.running_container_count }
    end

    def start_container(*args)
      instance = least_used_instance
      instance.start_container(*args)
    end

    def find_load_balancer_containers(*args)
      cluster_instances.flat_map do |ci|
        ci.find_load_balancer_containers(*args)
      end
    end
  end
end
