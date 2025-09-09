# frozen_string_literal: true

require 'ostruct'

RSpec.describe MaisPersonClient do
  # NOTE: This spec uses vcr cassettes from the MAIS API that were edited to obscure access tokens.
  #   The 500 test is also hard to replicate since the API does not return 500s typically.
  #   If the cassettes are re-created, you need to edit the access tokens in the cassette files
  #   and in the expectations below.

  subject do
    described_class.configure(
      api_key: FAKE_API_KEY,
      api_cert: FAKE_API_CERT,
      base_url: 'https://registry-uat.stanford.edu'
    )
  end

  describe '#fetch_user' do
    let(:user_by_sunetid) { subject.fetch_user('petucket') }
    let(:bad_user_by_sunetid) { subject.fetch_user('totally-bogus') }

    it 'retrieves a single user by sunetid' do
      VCR.use_cassette('Mais_Client/_fetch_user/retrieves user') do
        expect(user_by_sunetid).to be_a(String)
        expect(user_by_sunetid).to match(/<\?xml/)
        expect(user_by_sunetid).to include('<Person>REDACTED</Person>')
      end
    end

    context 'when a sunetid user is not found' do
      it 'returns nil' do
        VCR.use_cassette('Mais_Client/_fetch_user/raises') do
          expect(bad_user_by_sunetid).to be_nil
        end
      end
    end
  end
end
