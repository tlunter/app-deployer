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
      cluster_instances.min_by(&:running_container_count)
    end

    def start_container(*args)
      instance = least_used_instance
      instance.start_container(*args)
    end

    def find_containers(container, version)
      container_name = Container.build_name(container.name, '')

      containers.select do |docker_container|
        labels = docker_container.info['Labels']

        labels[Container::DEPLOYER_LABEL]                         && \
        labels[Container::NAME_LABEL].to_s.start_with?(container_name) && \
        labels[Container::VERSION_LABEL].to_s != version
      end
    end

    def find_load_balancer_containers(*args)
      cluster_instances.flat_map do |ci|
        ci.find_load_balancer_containers(*args)
      end
    end

    def containers
      cluster_instances.flat_map(&:containers)
    end
  end
end
