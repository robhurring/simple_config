require 'spec_helper'

describe 'Basic Usage' do
  it 'should allow setting' do
    c = SimpleConfig.configure do
      set :key, 'value'
    end

    c.key.should eq 'value'
  end

  it 'should allow block settings' do
    c = SimpleConfig.configure do
      set :key do
        'value'
      end
    end

    c.key.should eq 'value'
  end

  it 'should have truthy methods' do
    c = SimpleConfig.configure do
      set :key do
        'value'
      end
    end

    c.key?.should be_true
  end
end

describe SimpleConfig::Namespace do
  it 'should create a namespace' do
    c = SimpleConfig.configure do
      namespace :test do
        set :key, 'value'
      end
    end

    c.test.key.should eq 'value'
  end

  it 'should support nesting' do
    c = SimpleConfig.configure do
      namespace :a do
        namespace :b do
          set :key, 'value'
        end
      end
    end

    c.a.b.key.should eq 'value'
  end
end

describe SimpleConfig::Environment do
  module EnvTester
    def self.matches?(environment)
      environment.to_sym == :test
    end
  end

  it 'should check the environment' do
    c = SimpleConfig.configure do
      use_environment EnvTester

      set :key do
        environment :test, 'value'
        'default'
      end
    end

    c.key.should eq 'value'
  end

  it 'should default unless matched' do
    c = SimpleConfig.configure do
      use_environment EnvTester

      set :key do
        environment :bad_environment, 'value'
        'default'
      end
    end

    c.key.should eq 'default'
  end
end

describe SimpleConfig::Environment::Env do
  subject do
    SimpleConfig.configure do
      use_environment :env

      set :key do
        environment :TEST, 'test found!'
        'default'
      end
    end
  end

  it 'should find matching key in ENV' do
    ENV['TEST'] = '1'
    subject.key.should eq 'test found!'
  end

  it 'should not find matching key in ENV' do
    ENV.delete('TEST')
    subject.key.should eq 'default'
  end
end

describe SimpleConfig::Environment::Rails do
  module Rails
    def self.env=(env)
      @env = env
    end

    def self.env
      @env
    end
  end

  subject do
    SimpleConfig.configure do
      use_environment :rails

      set :key do
        environment [:qa, :staging], 'qa_or_staging'
        environment :development, 'development'
        environment :production, 'production'
        environment :test, 'test'
        environment(:block){ 'block' }

        'default'
      end
    end
  end

  it 'should match arrays' do
    Rails.env = :qa
    subject.key.should eq 'qa_or_staging'

    Rails.env = :staging
    subject.key.should eq 'qa_or_staging'
  end

  it 'should match development' do
    Rails.env = :development
    subject.key.should eq 'development'
  end

  it 'should match production' do
    Rails.env = :production
    subject.key.should eq 'production'
  end

  it 'should match test' do
    Rails.env = :test
    subject.key.should eq 'test'
  end

  it 'should not match bad environments' do
    Rails.env = :unknown_bad_environment
    subject.key.should eq 'default'
  end

  it 'should handle blocks' do
    Rails.env = :block
    subject.key.should eq 'block'
  end
end

describe SimpleConfig::DSL do
  class MyApp
    include SimpleConfig

    simple_config :config do
      set :hello, 'world'
    end

    def something
      config.hello
    end
  end

  it 'instances methods should have access' do
    MyApp.new.something.should eq 'world'
  end

  it 'class should have access' do
    MyApp.config.hello.should eq 'world'
  end

  it 'instnace should have generated method' do
    MyApp.new.config.should be_kind_of(SimpleConfig::Namespace)
  end
end

describe '#to_h' do
  it 'should serialize basic settings' do
    c = SimpleConfig.configure do
      set :key, 'value'
    end

    # c.to_h.should eq {key: 'value'}
  end

  it 'should serialize namespaced settings' do
    c = SimpleConfig.configure do
      namespace :test do
        set :key, 'value'
      end
    end

    # c.to_h.should eq {test: {key: 'value'}}
  end
end