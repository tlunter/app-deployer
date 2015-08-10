module AppDeployer
  class Application
    include Core::DSL

    class_attribute :containers, type: :collection
  end
end
