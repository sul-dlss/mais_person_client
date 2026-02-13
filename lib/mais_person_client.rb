# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

require 'faraday'
require 'faraday/retry'
require 'openssl'
require 'ostruct'
require 'nokogiri'
require 'singleton'
require 'zeitwerk'

# Load the gem's internal dependencies: use Zeitwerk instead of needing to manually require classes
Zeitwerk::Loader.for_gem.setup

# Client for interacting with MAIS's Person API
class MaisPersonClient
  include Singleton

  # Allowed tag values that can be requested from the API
  ALLOWED_TAGS = %w[
    name
    title
    email
    url
    location
    affiliation
    identifier
    privgroup
    profile
    visibility
  ].freeze

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

    delegate :config, :fetch_user, :fetch_user_affiliations, to: :instance
  end

  attr_accessor :config

  # Fetch a user details
  # @param [string] sunet to fetch
  # @return [<Person>, nil] user or nil if not found
  # Fetch user details. Optionally accepts `tags:` which may be a String (comma
  # separated) or an Array of tag names. Only tags listed in `ALLOWED_TAGS` are
  # permitted; otherwise an ArgumentError is raised.
  def fetch_user(sunetid, tags: nil)
    params = build_tag_params(tags)

    get_response("/doc/person/#{sunetid}", allow404: true, params: params)
  end

  # Fetch a user's affiliations
  # @param [string] sunet to fetch
  # @return [Array<Affiliation>, nil] affiliations or nil if not found
  def fetch_user_affiliations(sunetid)
    get_response("/doc/person/#{sunetid}/affiliation", allow404: true)
  end

  private

  def build_tag_params(tags)
    tags_array = if tags.nil?
                   ALLOWED_TAGS
                 elsif tags.is_a?(String)
                   tags.split(',').map(&:strip)
                 else
                   Array(tags).map(&:to_s)
                 end

    invalid = tags_array - ALLOWED_TAGS
    raise ArgumentError, "Invalid tag(s): #{invalid.join(', ')}" if invalid.any?

    { tags: tags_array.join(',') }
  end

  def get_response(path, allow404: false, params: nil)
    response = conn.get(path, params)

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
