# SimpleConfig

An alternative to using rails' environment files or YAML for application config. SimpleConfig was created out of the frustration of
missing a config setting in an environment file, or constantly duplicating YAML keys for different environments. SimpleConfig helps
make your config "safe" by always having a default value, and its built using Ruby so it is highly customizable and powerful.

Check the Usage for some details on how it can be used.

## Installation

Add this line to your application's Gemfile:

    gem 'simple_config'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_config

## Usage

### Basic Usage

```ruby
$config = SimpleConfig.configure do
  # basic set, similar to capistrano and sinatra
  set :username, 'user'
  set :password, 's3kr1t'

  # namespace support to keep config clean
  namespace :tracking do
    set :enabled, true
  end

  set :block do
    'blocks are allowed too!'
  end
end

if params[:user] == $config.username && params[:password] == $config.password
  ...
end

# all settings have a "presence" method, just add a "?" to check if it has been set
if $config.tracking.enabled?
  ...
end
```

### Rails Integration

```ruby
# config/initializers/app_config.rb
$config = SimpleConfig.configure do
  use_environment :rails

  set :username do
    # checks Rails.env and will return 'superadmin' when in production
    environment :production, 'superadmin'

    # defaults back to 'devuser' if environment doesn't match
    'devuser'
  end

  set :password do
    environment :production, 's3kr1t'

    'defaultpassword'
  end

  set :tracking do
    # check if we're in production _or_ staging
    environment [:production, :staging], true
    false
  end
end

# some_controller.rb
http_basic_authenticate_with name: $config.username, password: $config.password
```

### Advanced Integration

```ruby
class MyApp
  # include the SimpleConfig DSL
  include SimpleConfig

  # create a custom environment tester, any object that respond to #matches?(value) can be used
  # as an environment tester. This is in the core code when using "use_environment :env"
  module EnvironmentTester
    def self.matches?(environment)
      ::ENV.has_key?(environment.to_s.upcase)
    end
  end

  # creates a class and instance method +config+ that holds all settings
  simple_config :config do
    # use our custom env tester for all +environment+ calls
    use_environment EnvironmentTester

    set :redis_uri do
      # check our ENV for the REDIS_TO_GO_URL key
      environment :REDIS_TO_GO_URL do
        ENV['REDIS_TO_GO_URL']
      end

      # default to localhost if not found
      'localhost:6379'
    end
  end

  def redis
    Redis.new(config.redis_uri)
  end
end

$app = MyApp.new
$redis = $app.redis
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
