module AppDeployer
  class LoadBalancer
    include Core::DSL

    attribute :location, default: :local
    attribute :upstream, required: true

    def remote(hash)
      self.location = hash
    end

    def local
      self.location = :local
    end
  end
end
