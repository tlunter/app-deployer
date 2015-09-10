module AppDeployer
  class Application
    include Core::DSL

    class_attribute :containers, type: :collection
    class_attribute :cluster

    def start(version)
      ordered_containers.each do |container|
        (1..container.scale).each do |number|
          cluster.start_container(container, number, version)
        end
      end
    end

    def find_load_balancer_ports(version)
      lb_containers = containers.select(&:appear_in_load_balancer)
        .map { |c| AppDeployer::Container.build_name(c.name, '') }
      cluster.find_load_balancer_containers(lb_containers, version)
    end

    def destroy_old(version)
      ordered_containers.reverse_each do |container|
        old_containers = cluster.find_containers(container, version)
        old_containers.each { |c| c.delete(force: true) }
      end
    end

    private

    def ordered_containers
      return to_enum(:ordered_containers) unless block_given?
      container_dependents = Hash[containers.map { |c| [c, c.dependents] }]
      started_containers = []
      until container_dependents.empty?
        container_dependents.each do |container, dependents|
          if (dependents - started_containers).empty?
            yield container

            container_dependents.delete(container)
            started_containers << container
          end
        end
      end
    end
  end
end
