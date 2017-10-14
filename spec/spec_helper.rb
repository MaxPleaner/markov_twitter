require 'markov_twitter'
require 'dotenv'
require 'pry-byebug'

# can disable webmock by passing an option in the environment variables,
# e.g.
#          env DisableWebmock=true rspec
#
require('webmock/rspec') unless ENV["DisableWebmock"] == "true"

# Loads environment variables from .env file, which should be in gitignore.
# See .env.example, which is included in source control.
Dotenv.load

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end


