module AppDeployer
  class Cluster
    include Core::DSL

    class_attribute :cluster_instances, type: :collection

    def test_connectivity
      cluster_instances.reduce(true) do |memo, ci|
        memo &&= ci.test_connectivity
      end
    end
  end
end
