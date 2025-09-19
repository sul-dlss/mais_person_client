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
    let(:user_by_sunetid_with_tags) { subject.fetch_user('petucket', tags: %w[name title]) }
    let(:client) { subject.instance }

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

    it 'retrieves a single user by sunetid with tags' do
      VCR.use_cassette('Mais_Client/_fetch_user/retrieves user with tags') do
        expect(user_by_sunetid_with_tags).to be_a(String)
        expect(user_by_sunetid_with_tags).to match(/<\?xml/)
        expect(user_by_sunetid_with_tags).to include('<Person card="12345"')
        expect(user_by_sunetid_with_tags).to include('<Person card="12345"')
        expect(user_by_sunetid_with_tags).to include('<title type="job"')
        # assert that WebMock saw a GET with the tags query parameter
        expect(WebMock).to have_requested(:get, %r{https://registry-uat\.stanford\.edu/doc/person/petucket})
          .with(query: hash_including('tags' => 'name,title'))
      end
    end
  end

  describe '#fetch_user_affiliations' do
    let(:affiliations_by_sunetid) { subject.fetch_user_affiliations('petucket') }
    let(:bad_affiliations_by_sunetid) { subject.fetch_user_affiliations('totally-bogus') }
    let(:client) { subject.instance }

    it 'retrieves affiliations for a user by sunetid' do
      VCR.use_cassette('Mais_Client/_fetch_user_affiliations/retrieves affiliations') do
        expect(affiliations_by_sunetid).to be_a(String)
        expect(affiliations_by_sunetid).to match(/<\?xml/)
        expect(affiliations_by_sunetid).to include('<Person card="123456"')
        expect(affiliations_by_sunetid).to include('<organization adminid="JFBK" level2orgid="JAAA"')
      end
    end

    context 'when a sunetid user is not found' do
      it 'returns nil' do
        VCR.use_cassette('Mais_Client/_fetch_user_affiliations/raises') do
          expect(bad_affiliations_by_sunetid).to be_nil
        end
      end
    end
  end
end
