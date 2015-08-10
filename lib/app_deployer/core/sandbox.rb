module AppDeployer
  module Core
    class Sandbox
      include Singleton

      attr_reader :objects

      def initialize
        @objects = Hash.new { |hash, key| hash[key] = {} }
      end

      def [](obj_name)
        objects[obj_name]
      end
    end
  end
end
