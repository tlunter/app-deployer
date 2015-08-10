module AppDeployer
  class Cluster
    include Core::DSL

    attribute :location, default: :local

    def remote(hash)
      self.location = hash
    end

    def local
      self.location = :local
    end
  end
end
