module AppDeployer
  class Application
    include Core::DSL

    class_attribute :containers, type: :collection
    class_attribute :cluster

    def check_cluster_connectivity
      cluster.cluster_instances.each do |ci|
      end
    end
  end
end
