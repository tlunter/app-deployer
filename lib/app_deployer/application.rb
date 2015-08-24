module AppDeployer
  class Application
    include Core::DSL

    class_attribute :containers, type: :collection
    class_attribute :cluster

    def start
      ordered_containers.each do |container|
        (1..container.scale).each do |number|
          cluster.start_container(container, number)
        end
      end
    end

    def find_load_balancer_ports
      lb_containers = containers.select(&:appear_in_load_balancer)
        .map { |c| AppDeployer::Container.build_name(c.name, nil) }
      cluster.find_load_balancer_containers(lb_containers)
    end

    private

    def ordered_containers
      return to_enum(:ordered_containers) unless block_given?
      container_dependents = Hash[containers.map { |c| [c, c.dependents] }]
      started_containers = []
      until container_dependents.empty?
        puts "Started Containers: #{started_containers}"
        container_dependents.each do |container, dependents|
          puts "Container: #{container.name}"
          puts "Dependents: #{dependents.map(&:name)}"
          puts "Remaining: #{(dependents - started_containers).map(&:name)}"
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
