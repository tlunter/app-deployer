module AppDeployer
  class Container
    include Core::DSL

    attribute :scale

    attribute :image
    attribute :hostname
    attribute :links, default: []
    attribute :volumes, default: []
    attribute :volumes_from, default: []
    attribute :ports, default: []
    attribute :command
  end
end
