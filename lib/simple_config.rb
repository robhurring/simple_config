# SimpleConfig
# Settings module that can be easily included into classes that store
# your applications configuration
module SimpleConfig
  VERSION = '0.1'

  module ClassMethods
    # Public: Create a settings namespace.
    #
    # block - instance eval'd block
    #
    # Examples
    #
    #   class Klass
    #     include SimpleConfig
    #   end
    #
    #   Klass.configure do
    #     set :key, 'value'
    #   end
    #
    # Returns global namespace
    def configure(&block)
      Namespace.new &block
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module Environment
    autoload :Rails, 'simple_config/environment/rails'
    autoload :Env, 'simple_config/environment/env'
  end

  class SettingBlock
    def initialize(environment = nil, &block)
      @block = lambda &block
      @environment = environment
    end

    def call
      catch(:done){ instance_eval &@block }
    end

  private

    def environment(name_or_names, value, &block)
      return unless @environment

      if Array(name_or_names).any?{ |n| @environment.matches?(n) }
        return_value = block_given? ? block.call : value
        throw :done, return_value
      end
    end
  end

  class Setting
    def initialize(namespace, key, value, &block)
      @key = key
      value = SettingBlock.new(namespace.environment, &block) if block_given?
      @value = value
    end

    def value
      if @value.respond_to?(:call)
        @value.call
      else
        @value
      end
    end
  end

  class Namespace
    attr_reader :environment

    def initialize(name = nil, &block)
      @name = name
      @environment = nil
      instance_eval &block
    end

    def use_environment(klass = nil)
      return if klass.nil?

      if klass.is_a?(Symbol)
        klass = Object.module_eval("SimpleConfig::Environment::#{klass.to_s.capitalize}", __FILE__, __LINE__)
      else
        unless klass.is_a?(Object) && klass.respond_to?(:matches?)
          raise "#{klass} must respond to #matches?(value) to be a valid environment!"
        end
      end

      @environment = klass
    end

    def set(name, value = nil, &block)
      define_metaclass_method(name.to_sym){ Setting.new(self, name, value, &block).value }
    end

    def namespace(name, &block)
      define_metaclass_method(name.to_sym) do
        namespace = Namespace.new(name, &block)
        namespace.use_environment(@environment)
        namespace
      end
    end

  private

    def define_metaclass_method(method, &block)
      (class << self; self; end).send :define_method, method, &block
    end
  end
end
