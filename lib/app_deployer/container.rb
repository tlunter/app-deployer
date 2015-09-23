module AppDeployer
  class Container
    include Core::DSL

    VERSION_LABEL = 'com.tlunter.app-deployer.version'
    NAME_LABEL = 'com.tlunter.app-deployer.name'
    DEPLOYER_LABEL = 'com.tlunter.app-deployer'

    attribute :scale, default: 1

    attribute :image
    attribute :hostname
    class_attribute :links, class_name: :containers, type: :collection
    attribute :volumes, default: []
    class_attribute :volumes_froms, class_name: :containers, type: :collection
    attribute :ports, default: []
    attribute :command
    attribute :environment

    attribute :appear_in_load_balancer, default: false

    def self.build_name(name, number=nil, version=nil)
      suffix = [name, number, version].compact.join('-')
      "app_deployer-#{suffix}"
    end

    def dependents
      (links + volumes_froms).uniq
    end

    def to_container_create_opts(number, version)
      {
        'name' => self.class.build_name(name, number, version),
        'Image' => image,
        'Hostname' => hostname,
        'Volumes' => volumes_config,
        'Labels' => {
          VERSION_LABEL => version,
          NAME_LABEL => self.class.build_name(name, number),
          DEPLOYER_LABEL => 'true'
        },
        'Cmd' => command,
        'ExposedPorts' => Hash[ports.map { |p| [p, {}] }],
        'Env' => environment_config,
        'HostConfig' => {
          'PublishAllPorts' => !ports.empty?,
          'Links' => links_config(version),
          'VolumesFrom' => volumes_from_config(version)
        }
      }
    end

    private
    def volumes_config
      Hash[Array.new(volumes).map do |volume|
        [volume.split(':')[1], {}]
      end]
    end

    def links_config(version)
      links.map do |container|
        [self.class.build_name(container.name, 1, version), container.name].join(':')
      end
    end

    def volumes_from_config(version)
      volumes_froms.map do |container|
        self.class.build_name(container.name, 1, version)
      end
    end

    def environment_config
      return [] if environment.nil?

      environment.dup.map do |k, v|
        "#{k}=#{v.nil? ? ENV[k.to_s] : v}"
      end
    end
  end
end
