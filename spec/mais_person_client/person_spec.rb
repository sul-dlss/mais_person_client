# frozen_string_literal: true

RSpec.describe MaisPersonClient::Person do
  let(:xml_string) { File.read(File.join(File.dirname(__dir__), 'fixtures', 'person_sample.xml')) }
  let(:person) { described_class.new(xml_string) }

  describe '#initialize' do
    it 'parses XML string and removes namespaces' do
      expect(person.xml).to be_a(Nokogiri::XML::Document)
      expect(person.xml.root.name).to eq('Person')
    end
  end

  describe 'root attributes' do
    it 'parses card attribute' do
      expect(person.card).to eq('123456789012345')
    end

    it 'parses listing attribute' do
      expect(person.listing).to eq('tooniverse')
    end

    it 'parses name attribute' do
      expect(person.name_attr).to eq('Duck, Donald Fauntleroy')
    end

    it 'parses regid attribute' do
      expect(person.regid).to eq('FAKE-REGID-0001')
    end

    it 'parses relationship attribute' do
      expect(person.relationship).to eq('adventurer')
    end

    it 'parses source attribute' do
      expect(person.source).to eq('cartoon')
    end

    it 'parses sunetid attribute' do
      expect(person.sunetid).to eq('donald')
    end

    it 'parses univid attribute' do
      expect(person.univid).to eq('00000001')
    end

    it 'parses stanford_end_date attribute' do
      xml_with_date = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Person stanfordenddate="2024-05-10">
          <name type="registered">Test User</name>
        </Person>
      XML
      person_with_date = described_class.new(xml_with_date)
      expect(person_with_date.stanford_end_date).to eq('2024-05-10')
    end

    it 'returns nil when stanford_end_date attribute is missing' do
      expect(person.stanford_end_date).to be_nil
    end

    it 'returns nil when stanford_end_date attribute is blank' do
      xml_blank = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Person stanfordenddate="">
          <name type="registered">Test User</name>
        </Person>
      XML
      person_blank = described_class.new(xml_blank)
      expect(person_blank.stanford_end_date).to be_nil
    end
  end

  describe 'names' do
    it 'returns an array of PersonName structs' do
      names = person.names
      expect(names).to be_an(Array)
      expect(names.length).to eq(2)
      expect(names.first).to be_a(MaisPersonClient::Person::PersonName)
    end

    it 'parses name attributes correctly' do
      registered_name = person.names.find { |n| n.type == 'registered' }
      expect(registered_name.type).to eq('registered')
      expect(registered_name.visibility).to eq('none')
      expect(registered_name.first_name).to eq('Donald')
      expect(registered_name.first_nval).to eq('donald')
      expect(registered_name.middle).to eq('Fauntleroy')
      expect(registered_name.middle_nval).to eq('fauntleroy')
      expect(registered_name.last).to eq('Duck')
      expect(registered_name.last_nval).to eq('duck')
    end

    describe '#registered_name' do
      it 'returns the registered name' do
        name = person.registered_name
        expect(name.type).to eq('registered')
        expect(name.first_name).to eq('Donald')
      end
    end

    describe '#display_name' do
      it 'returns the display name' do
        name = person.display_name
        expect(name.full_name).to eq('Donald Duck')
        expect(name.type).to eq('display')
        expect(name.visibility).to eq('world')
      end
    end

    describe '#first_name' do
      it 'returns the first name from registered name' do
        expect(person.first_name).to eq('Donald')
      end
    end

    describe '#middle_name' do
      it 'returns the middle name from registered name' do
        expect(person.middle_name).to eq('Fauntleroy')
      end
    end

    describe '#last_name' do
      it 'returns the last name from registered name' do
        expect(person.last_name).to eq('Duck')
      end
    end
  end

  describe 'titles' do
    it 'returns an array of title hashes' do
      titles = person.titles
      expect(titles).to be_an(Array)
      expect(titles.length).to eq(1)
      expect(titles.first).to be_a(Hash)
    end

    it 'parses title attributes correctly' do
      title = person.titles.first
      expect(title[:type]).to eq('job')
      expect(title[:visibility]).to eq('world')
      expect(title[:title]).to eq('Chief Quack Officer')
    end

    describe '#job_title' do
      it 'returns the job title' do
        expect(person.job_title).to eq('Chief Quack Officer')
      end
    end
  end

  describe 'emails' do
    it 'returns an array of Email structs' do
      emails = person.emails
      expect(emails).to be_an(Array)
      expect(emails.length).to eq(2)
      expect(emails.first).to be_a(MaisPersonClient::Person::Email)
    end

    it 'parses email attributes correctly' do
      primary = person.emails.find { |e| e.type == 'primary' }
      expect(primary.type).to eq('primary')
      expect(primary.visibility).to eq('world')
      expect(primary.user).to eq('donald.duck')
      expect(primary.host).to eq('duckmail.com')
    end

    describe '#primary_email' do
      it 'returns the primary email address' do
        expect(person.primary_email).to eq('donald.duck@duckmail.com')
      end
    end
  end

  describe 'urls' do
    it 'returns an array of Url structs' do
      urls = person.urls
      expect(urls).to be_an(Array)
      expect(urls.length).to eq(1)
      expect(urls.first).to be_a(MaisPersonClient::Person::Url)
    end

    it 'parses url attributes correctly' do
      homepage = person.urls.first
      expect(homepage.type).to eq('homepage')
      expect(homepage.visibility).to eq('world')
      expect(homepage.url).to eq('http://donalds-adventures.duck')
    end

    describe '#homepage' do
      it 'returns the homepage URL' do
        expect(person.homepage).to eq('http://donalds-adventures.duck')
      end
    end
  end

  describe 'locations' do
    it 'returns an array of Location structs' do
      locations = person.locations
      expect(locations).to be_an(Array)
      expect(locations.length).to eq(1)
      expect(locations.first).to be_a(MaisPersonClient::Person::Location)
    end

    it 'parses location attributes correctly' do
      location = person.locations.first
      expect(location.code).to eq('1313')
      expect(location.type).to eq('idmail')
      expect(location.visibility).to eq('world')
      expect(location.location).to eq('MONEY BIN - TOP FLOOR')
    end
  end

  describe 'affiliations' do
    it 'returns an array of Affiliation structs' do
      affiliations = person.affiliations
      expect(affiliations).to be_an(Array)
      expect(affiliations.length).to eq(1)
      expect(affiliations.first).to be_a(MaisPersonClient::Person::Affiliation)
    end

    it 'parses affiliation with department and affdata' do
      affiliation = person.affiliations.first
      expect(affiliation.affnum).to eq('1')
      expect(affiliation.effective).to eq('1934-06-09')
      expect(affiliation.organization).to eq('tooncorp')
      expect(affiliation.type).to eq('staff')
      expect(affiliation.visibility).to eq('world')

      # Test department
      expect(affiliation.department).to be_a(MaisPersonClient::Person::Department)
      expect(affiliation.department.name).to eq('Duckburg Adventurers Club')
      expect(affiliation.department.organization).to eq('Duckburg Adventurers Club')
      expect(affiliation.department.adminid).to eq('DUCK')

      # Test affdata
      expect(affiliation.affdata).to be_an(Array)
      expect(affiliation.affdata.first).to be_a(MaisPersonClient::Person::AffData)
      expect(affiliation.affdata.find { |ad| ad.type == 'job' }.code).to eq('313')

      # Test places within affiliation
      expect(affiliation.place).to be_an(Array)
      expect(affiliation.place.first).to be_a(MaisPersonClient::Person::Place)
    end

    describe '#primary_org_code' do
      it 'returns the department adminid for affnum=1' do
        expect(person.primary_org_code).to eq('DUCK')
      end

      it 'returns nil when affiliation with affnum=1 is missing' do
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person>
            <affiliation affnum="2">
              <department affnum="2">
                <organization adminid="NOMAIN">Dept</organization>
              </department>
            </affiliation>
          </Person>
        XML

        p = described_class.new(xml)
        expect(p.primary_org_code).to be_nil
      end
    end

    describe '#primary_effective_date' do
      it 'returns the effective date for affiliation with affnum=1' do
        expect(person.primary_effective_date).to eq('1934-06-09')
      end

      it 'returns nil when affiliation with affnum=1 is missing' do
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person>
            <affiliation affnum="2" effective="2020-01-01" />
          </Person>
        XML

        p = described_class.new(xml)
        expect(p.primary_effective_date).to be_nil
      end
    end

    describe '#primary_role' do
      it 'returns the affiliation type for affnum=1' do
        expect(person.primary_role).to eq('staff')
      end

      it 'returns nil when affiliation with affnum=1 is missing' do
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person>
            <affiliation affnum="2" type="faculty"/>
          </Person>
        XML

        p = described_class.new(xml)
        expect(p.primary_role).to be_nil
      end
    end

    describe '#academic_council?' do
      it 'returns false when not marked "Member of Academic Council" in affdata' do
        # The fixture has an affdata type 'club' and does not mark academic_council as NON-MEMBER
        expect(person.academic_council?).to be false
      end

      it 'returns false when an affiliation has affdata academic_council NON-MEMBER' do
        # Build a minimal person XML with an affiliation that includes affdata type academic_council = NON-MEMBER
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person>
            <affiliation affnum="1">
              <affdata affnum="1" type="academic_council">NON-MEMBER</affdata>
            </affiliation>
          </Person>
        XML

        p = described_class.new(xml)
        expect(p.academic_council?).to be false
      end

      it 'returns true when an affiliation has affdata academic_council "Member of Academic Council"' do
        # Build a minimal person XML with an affiliation that includes affdata type academic_council = NON-MEMBER
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person>
            <affiliation affnum="1">
              <affdata affnum="1" type="academic_council">Member of Academic Council</affdata>
            </affiliation>
          </Person>
        XML

        p = described_class.new(xml)
        expect(p.academic_council?).to be true
      end
    end
  end

  describe 'identifiers' do
    it 'returns an array of Identifier structs' do
      identifiers = person.identifiers
      expect(identifiers).to be_an(Array)
      expect(identifiers.length).to eq(6)
      expect(identifiers.first).to be_a(MaisPersonClient::Person::Identifier)
    end

    it 'parses identifier attributes correctly' do
      regid = person.identifiers.find { |i| i.type == 'regid' }
      expect(regid.type).to eq('regid')
      expect(regid.visibility).to eq('none')
      expect(regid.nval).to eq('FAKE-REGID-0001')
      expect(regid.value).to eq('FAKE-REGID-0001')
    end

    describe '#identifier_by_type' do
      it 'returns identifier value by type' do
        expect(person.identifier_by_type('directory')).to eq('DUCK313')
        expect(person.identifier_by_type('univid')).to eq('00000001')
      end
    end

    describe '#orcid' do
      it 'returns the ORCID identifier' do
        expect(person.orcid).to eq('https://orcid.org/0000-0000-0000-1313')
      end
    end

    describe '#directory_id' do
      it 'returns the directory ID' do
        expect(person.directory_id).to eq('DUCK313')
      end
    end
  end

  describe 'privgroups' do
    it 'returns an array of privacy group names' do
      groups = person.privgroups
      expect(groups).to be_an(Array)
      expect(groups).to include('toon:adventurers')
      expect(groups).to include('toon:ducktales')
      expect(groups).to include('toon:moneybin')
    end
  end

  describe 'eduPerson attributes' do
    describe '#eduperson_primary_affiliation' do
      it 'returns the primary affiliation' do
        expect(person.eduperson_primary_affiliation).to eq('adventurer')
      end
    end

    describe '#eduperson_affiliations' do
      it 'returns an array of affiliations' do
        affiliations = person.eduperson_affiliations
        expect(affiliations).to be_an(Array)
        expect(affiliations).to include('member')
        expect(affiliations).to include('adventurer')
      end
    end
  end

  describe 'struct definitions' do
    it 'defines all required struct classes' do
      expect(defined?(MaisPersonClient::Person::PersonName)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Address)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Telephone)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Email)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Url)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Location)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Identifier)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Department)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Affiliation)).to be_truthy
      expect(defined?(MaisPersonClient::Person::AffData)).to be_truthy
      expect(defined?(MaisPersonClient::Person::Place)).to be_truthy
    end
  end

  describe 'edge cases' do
    context 'with minimal XML' do
      let(:minimal_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person regid="test123" sunetid="testuser">
            <name type="registered" visibility="world">Test User</name>
          </Person>
        XML
      end
      let(:minimal_person) { described_class.new(minimal_xml) }

      it 'handles missing optional elements gracefully' do
        expect(minimal_person.regid).to eq('test123')
        expect(minimal_person.sunetid).to eq('testuser')
        expect(minimal_person.names.length).to eq(1)
        expect(minimal_person.emails).to be_empty
      end

      it 'returns false for academic_council? when there are no affiliations' do
        expect(minimal_person.academic_council?).to be false
      end
    end

    context 'with malformed XML' do
      let(:bad_xml) { '<invalid>xml</notclosed>' }

      it 'still parses what it can' do
        expect { described_class.new(bad_xml) }.not_to raise_error
      end
    end
  end
end
