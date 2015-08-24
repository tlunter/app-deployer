module AppDeployer
  module Core
    class Sandbox
      include Singleton

      attr_reader :objects

      def initialize
        @objects = Hash.new { |hash, key| hash[key] = {} }
      end

      def find_and_eval(file_name:)
        directory = Dir.pwd
        file = nil

        until File.dirname(directory) == directory
          if File.exist?(File.join(directory, file_name))
            file = File.join(directory, file_name)
            break
          else
            directory = File.dirname(directory)
          end
        end

        instance_eval(File.read(file), file) unless file.nil?
      end

      def [](obj_name)
        objects[obj_name]
      end
    end
  end
end
