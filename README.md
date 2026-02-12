[![Gem Version](https://badge.fury.io/rb/mais_person_client.svg)](https://badge.fury.io/rb/mais_person_client)
[![CircleCI](https://circleci.com/gh/sul-dlss/mais_person_client.svg?style=svg)](https://circleci.com/gh/sul-dlss/mais_person_client)
[![codecov](https://codecov.io/github/sul-dlss/mais_person_client/graph/badge.svg?token=A6B03FJ981)](https://codecov.io/github/sul-dlss/mais_person_client)

# mais_person_client
API client for accessing MAIS's Person endpoints.

MAIS's Person API provides access to information for Stanford users.

## API Documentation

API docs: https://uit.stanford.edu/developers/apis/person
API Schema: https://uit.stanford.edu/service/registry/person-data

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add mais_person_client

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install mais_person_client

## Usage

For one-off requests:

```ruby
require "mais_person_client"

# NOTE: The settings below live in the consumer, not in the gem.
# The user_agent string can be changed by consumers as requested by MaIS for tracking
client = MaisPersonClient.configure(
  api_key: Settings.mais_person.api_key,
  api_cert: Settings.mais_person.api_cert,
  base_url: Settings.mais_person.base_url,
  user_agent: 'some-user-agent-string-to-send-in-requests' # defaults to 'stanford-library'
)
result = client.fetch_user('nataliex') # get a single user by sunet, returns an XML doc as a string

person = MaisPersonClient::Person.new(result) # returns a class with the XML parsed
person.sunetid
=> 'donaldduck'

result = client.fetch_affiliations('nataliex') # get a single users organization affiliations, returns an XML doc as a string
affiliations = MaisPersonClient::Affiliations.new(result) # returns a class with the XML parsed
# Get all affiliations
affiliations_list = affiliations.affiliations
active_faculty = affiliations.faculty_affiliations
primary = affiliations.primary_affiliation
primary_org_id = affiliations.primary_org_id
all_org_ids = affiliations.org_ids
```

You can also invoke methods directly on the client class, which is useful in a Rails application environment where you might initialize the client in an
initializer and then invoke client methods in many other contexts where you want to be sure configuration has already occurred, e.g.:

```ruby
# config/initializers/mais_person_client.rb
MaisPersonClient.configure(
  api_key: Settings.mais_person.api_key,
  api_cert: Settings.mais_person.api_cert,
  base_url: Settings.mais_person.base_url,
)

# app/services/my_mais_person_service.rb
# ...
def get_user(sunet)
  MaisPersonClient.fetch_user(sunet)
end
# ...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## VCR Cassettes

VCR gem is used to record the results of the API calls for the tests.  If you need to record or re-create existing cassettes, you may need to adjust expectations in the tests as the results coming back from the API may be different than when the cassettes were recorded.

To record new cassettes:
1. Join VPN.
2. Temporarily adjust the configuration (fake_api_key, fake_api_cert for the MaIS UAT URL) at the top of `spec/spec_helper.rb` so it matches the real MaIS UAT environment.
3. Add your new spec with a new cassette name (or delete a previous cassette to re-create it).
4. Run just that new spec (important: else previous specs may use cassettes that have redacted credentials, causing your new spec to fail).
5. You should get a new cassette with the name you specified in the spec.
6. Look at the cassette.  If it has real person data, you will want to redact most of it since there will be private information in there.  Make the expectation match the redaction.
7. Set your configuration at the top of the spec back to the fake api_key and api_cert values.
8. The spec that checks for a raised exception when fetching all users may need to be handcrafted in the cassette to look it raised a 500.  It's hard to get the actual URL to produce a 500 on this call.
9. Re-run all the specs - they should pass now without making real calls.
