require 'app_deployer'
require 'pry'

module AppDeployer
  class CLI < Thor
    class_option :file, type: :string, default: 'Appfile'
    class_option :version, default: AppDeployer.git_sha

    no_commands do
      def setup
        AppDeployer::Core::Sandbox.instance.find_and_eval(file_name: options[:file])
      end
    end

    desc 'start-application DEPLOY', "start the deploy's application"
    def start_application(deploy)
      setup

      deploy = AppDeployer::Core::Sandbox.instance[:deploy][deploy.to_sym]
      deploy.start_application(options[:version])
    end

    desc 'validate-application-live DEPLOY', "validate the deploy's application is live"
    def validate_application_live(deploy)
      setup

      deploy = AppDeployer::Core::Sandbox.instance[:deploy][deploy.to_sym]
      deploy.validate_application_live(options[:version])
    end

    desc 'destroy-old-application DEPLOY', "destroy this application's old deploys"
    def destroy_old_application(deploy)
      setup

      deploy = AppDeployer::Core::Sandbox.instance[:deploy][deploy.to_sym]
      deploy.destroy_old_application(options[:version])
    end

    desc 'update-load-balancer DEPLOY', "update the deploy's load-balancer upstream with current application routes"
    def update_load_balancer(deploy)
      setup

      deploy = AppDeployer::Core::Sandbox.instance[:deploy][deploy.to_sym]
      deploy.assign_app_ports_to_load_balancer(options[:version])
      deploy.reload_load_balancer
    end
  end
end

