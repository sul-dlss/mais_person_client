# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

require 'mais_person_client'
require 'byebug'
require 'webmock/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

WebMock.enable!

# the fake client key and cert used in spec tests for MaIS API (and used to sanitize)
FAKE_API_KEY = "-----BEGIN PRIVATE KEY-----\nfakekey\n-----END PRIVATE KEY-----"
FAKE_API_CERT = "-----BEGIN CERTIFICATE-----\nfakecert\n-----END CERTIFICATE-----"

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :once
  }
  c.configure_rspec_metadata!
end
