# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

require 'faraday'
require 'faraday/retry'
require 'openssl'
require 'ostruct'
require 'singleton'
require 'zeitwerk'

# Load the gem's internal dependencies: use Zeitwerk instead of needing to manually require classes
Zeitwerk::Loader.for_gem.setup

# Client for interacting with MAIS's Person API
class MaisPersonClient
  include Singleton

  class << self
    # @param api_key [String] the api_key provided by MAIS
    # @param api_cert [String] the api_cert provided by MAIS
    # @param base_url [String] the base URL for the API
    # @param user_agent [String] the user agent to use for requests (default: 'stanford-library')
    def configure(api_key:, api_cert:, base_url:, user_agent: 'stanford-library')
      # rubocop:disable Style/OpenStructUse
      instance.config = OpenStruct.new(
        api_key:,
        api_cert:,
        base_url:,
        user_agent:
      )
      # rubocop:enable Style/OpenStructUse

      self
    end

    delegate :config, :fetch_user, to: :instance
  end

  attr_accessor :config

  # Fetch a user details
  # @param [string] sunet to fetch
  # @return [<Person>, nil] user or nil if not found
  def fetch_user(sunetid)
    get_response("/doc/person/#{sunetid}", allow404: true)
  end

  private

  def get_response(path, allow404: false)
    response = conn.get(path)

    return if allow404 && response.status == 404

    return UnexpectedResponse.call(response) unless response.success?

    response.body
  end

  def conn
    conn = Faraday.new(url: config.base_url) do |faraday|
      configure_faraday(faraday)
    end
    conn.options.timeout = 500
    conn.options.open_timeout = 10
    conn.headers[:user_agent] = config.user_agent
    conn
  end

  def configure_faraday(faraday)
    faraday.request :retry, max: 3,
                            interval: 0.5,
                            interval_randomness: 0.5,
                            backoff_factor: 2

    # Configure SSL for client certificate authentication (unless we are using bogus fake values in spec)
    return if config.api_key.include?('fakekey')

    cert = OpenSSL::X509::Certificate.new(config.api_cert)
    key = OpenSSL::PKey::RSA.new(config.api_key)
    faraday.ssl.client_cert = cert
    faraday.ssl.client_key = key
  end
end
