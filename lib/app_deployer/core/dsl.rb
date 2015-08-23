module AppDeployer
  module Core
    module DSL
      def self.included(mod)
        super

        add_method_to_sandbox(mod)
        mod.extend(ClassMethods)
        mod.attribute(:name, required: true)
      end

      # Adds a method with the underscored version of the name to
      # AppDeployer::Core::Sandbox
      def self.add_method_to_sandbox(mod)
        module_name = mod.name.demodulize
        name = module_name.underscore.to_sym
        Sandbox.send(:define_method, name) do |*args, &block|
          if args.empty? || !args.first.is_a?(Symbol)
            raise "Must pass at least a name to `##{name}`!"
          else
            Sandbox.instance[name][args.first] ||= mod.new(*args, &block)
          end
        end
      end

      module ClassMethods
        def default_values
          @default_values ||= {}
        end

        def required_values
          @required_values ||= []
        end

        def class_attribute(name, type: :record)
          name = name.to_sym
          @attributes ||= []
          @attributes << name
          @class_attributes ||= []
          @class_attributes << name

          if type == :record
            add_record_class_attribute(name)
          elsif type == :collection
            add_collection_class_attribute(name)
          end
        end

        def attribute(name, default: nil, required: false)
          name = name.to_sym
          @attributes ||= []
          @attributes << name

          default_values[name] = default
          required_values << name if required
          define_method(name) do
            instance_variable_get(:"@#{name}")
          end
          define_method(:"#{name}=") do |arg = nil, &block|
            if arg.nil?
              instance_variable_set(:"@#{name}", block)
            else
              instance_variable_set(:"@#{name}", arg)
            end
          end
        end

        private

        def add_record_class_attribute(name)
          default_values[name] = nil
          define_method(name) do |*args, &block|
            if args.empty?
              instance_variable_get(:"@#{name}")
            else
              attr_name = args.first
              Sandbox.instance[name][attr_name] ||= Sandbox.instance.send(name.to_sym, *args, &block)
              instance_variable_set(:"@#{name}", Sandbox.instance[name][attr_name])
            end
          end
        end

        def add_collection_class_attribute(name)
          singular = name.to_s.singularize.to_sym
          default_values[name] = []

          if singular == name
            raise "Expecting #{name} to have been plural!"
          end

          define_method(name) do |*args, &block|
            instance_variable_get(:"@#{name}")
          end

          define_method("#{name}=") do |*args, &block|
            instance_variable_set(:"@#{name}", *args, &block)
          end

          define_method(singular) do |*args, &block|
            if args.empty? || !args.first.is_a?(Symbol)
              raise "Must pass at least a name to `##{singular}`!"
            else
              attr_name = args.first
              Sandbox.instance[singular][attr_name] ||= Sandbox.instance.send(singular.to_sym, *args, &block)
              send(name.to_sym) << Sandbox.instance[singular][attr_name]
            end
          end
        end
      end

      def initialize(*args, &block)
        self.class.default_values.each do |key, value|
          if value.nil?
            instance_variable_set(:"@#{key}", nil)
          elsif value.is_a?(Proc)
            instance_variable_set(:"@#{key}", value.call)
          elsif value.is_a?(Symbol)
            instance_variable_set(:"@#{key}", value)
          else
            instance_variable_set(:"@#{key}", value.dup)
          end
        end

        self.name = args.first

        before_initialize
        if args.last.is_a?(Hash)
          options = args.pop
          options.each do |key, value|
            send("#{key}=", value)
          end
        end
        if block
          instance_eval(&block)
        end
        validate_required!
        after_initialize
      end

      def validate_required!
        self.class.required_values.each do |key|
          if send(key).nil?
            raise "#{key} cannot be nil!"
          end
        end
      end

      def before_initialize
      end

      def after_initialize
      end
    end
  end
end
