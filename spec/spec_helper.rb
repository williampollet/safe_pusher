require "bundler/setup"
require "safe_pusher"

RSpec.configure do |config|
  config.before(:all) do
    SafePusher.configure do |config|
      config.test_command = 'bundle exec rspec'
      config.files_to_test = %w[lib/]
    end
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
