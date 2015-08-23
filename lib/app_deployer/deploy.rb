module AppDeployer
  class Deploy
    include Core::DSL

    attribute :s3_location
    class_attribute :load_balancer
    class_attribute :application
  end
end
