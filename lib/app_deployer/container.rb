module AppDeployer
  class Container
    include Core::DSL

    attribute :scale, default: 1

    attribute :image
    attribute :hostname
    class_attribute :links, class_name: :containers, type: :collection
    attribute :volumes, default: []
    class_attribute :volumes_froms, class_name: :containers, type: :collection
    attribute :ports, default: []
    attribute :command

    attribute :appear_in_load_balancer, default: false

    def self.build_name(name, number)
      "app_deployer-#{name}-#{number}"
    end

    def dependents
      (links + volumes_froms).uniq
    end

    def to_container_create_opts(number, version)
      {
        'name' => self.class.build_name(name, number),
        'Image' => image,
        'Hostname' => hostname,
        'Volumes' => volumes_config,
        'Labels' => {
          'com.tlunter.app-deployer.version': version,
          'com.tlunter.app-deployer.name': self.class.build_name(name, number),
          'com.tlunter.app-deployer': 'true'
        },
        'Cmd' => command,
        'ExposedPorts' => Hash[ports.map { |p| [p, {}] }],
        'HostConfig' => {
          'PublishAllPorts' => !ports.empty?,
          'Links' => links_config,
          'VolumesFrom' => volumes_from_config
        }
      }
    end

    private
    def volumes_config
      Hash[Array.new(volumes).map do |volume|
        [volume.split(':')[1], {}]
      end]
    end

    def links_config
      links.map do |container|
        [self.class.build_name(container.name, 1), container.name].join(':')
      end
    end

    def volumes_from_config
      volumes_froms.map do |container|
        self.class.build_name(container.name, 1)
      end
    end
  end
end
