# frozen_string_literal: true

RSpec.describe MaisPersonClient::Affiliations do
  let(:xml_string) { File.read(File.join(__dir__, '..', 'fixtures', 'affiliations_sample.xml')) }
  let(:affiliations) { described_class.new(xml_string) }

  describe '#initialize' do
    it 'parses XML string and removes namespaces' do
      expect(affiliations.xml).to be_a(Nokogiri::XML::Document)
      expect(affiliations.xml.root.name).to eq('Person')
    end
  end

  describe 'root attributes' do
    it 'parses card attribute' do
      expect(affiliations.card).to eq('123456789012345')
    end

    it 'parses listing attribute' do
      expect(affiliations.listing).to eq('world')
    end

    it 'parses name attribute' do
      expect(affiliations.name_attr).to eq('Gadget, Inspector')
    end

    it 'parses regid attribute' do
      expect(affiliations.regid).to eq('FAKE-REGID-ABC123')
    end

    it 'parses relationship attribute' do
      expect(affiliations.relationship).to eq('faculty')
    end

    it 'parses source attribute' do
      expect(affiliations.source).to eq('registry')
    end

    it 'parses sunetid attribute' do
      expect(affiliations.sunetid).to eq('igadget')
    end

    it 'parses univid attribute' do
      expect(affiliations.univid).to eq('00000001')
    end
  end

  describe 'affiliations' do
    it 'returns an array of AffiliationRecord structs' do
      affiliations_list = affiliations.affiliations
      expect(affiliations_list).to be_an(Array)
      expect(affiliations_list.length).to eq(4)
      expect(affiliations_list.first).to be_a(MaisPersonClient::Affiliations::AffiliationRecord)
    end

    it 'parses affiliation attributes correctly' do
      first_affiliation = affiliations.affiliations.first
      expect(first_affiliation.affnum).to eq('1')
      expect(first_affiliation.effective).to eq('2024-09-01')
      expect(first_affiliation.organization).to eq('stanford')
      expect(first_affiliation.type).to eq('faculty')
      expect(first_affiliation.visibility).to eq('world')
      expect(first_affiliation.name).to eq('Faculty')
    end

    it 'parses department information' do
      first_affiliation = affiliations.affiliations.first
      department = first_affiliation.department
      expect(department).to be_a(MaisPersonClient::Affiliations::Department)
      expect(department.affnum).to eq('1')
      expect(department.name).to eq('Crime Detection')

      # Test organization within department
      org = department.organization
      expect(org).to be_a(MaisPersonClient::Affiliations::Organization)
      expect(org.adminid).to eq('CRIME')
      expect(org.level2orgid).to eq('DETECT')
      expect(org.level2orgname).to eq('School of Investigation')
      expect(org.regid).to eq('FAKE-ORG-DETECT-001')
      expect(org.name).to eq('Crime Detection Operations')
    end

    it 'parses description' do
      first_affiliation = affiliations.affiliations.first
      expect(first_affiliation.description).to eq('Chief Inspector')
    end

    it 'parses affdata array' do
      first_affiliation = affiliations.affiliations.first
      affdata = first_affiliation.affdata
      expect(affdata).to be_an(Array)
      expect(affdata.length).to eq(5)
      expect(affdata.first).to be_a(MaisPersonClient::Affiliations::AffData)

      # Test specific affdata entries
      academic_council = affdata.find { |ad| ad.type == 'academic_council' }
      expect(academic_council.value).to eq('Member of Detective Council')

      job_affdata = affdata.find { |ad| ad.type == 'job' }
      expect(job_affdata.code).to eq('007')
      expect(job_affdata.value).to eq('Chief Inspector')

      stdhrs = affdata.find { |ad| ad.type == 'stdhrs' }
      expect(stdhrs.value).to eq('42')
    end

    it 'parses place information with addresses and telephones' do
      first_affiliation = affiliations.affiliations.first
      places = first_affiliation.place
      expect(places).to be_an(Array)
      expect(places.length).to eq(1)

      place = places.first
      expect(place).to be_a(MaisPersonClient::Affiliations::Place)
      expect(place.affnum).to eq('1')
      expect(place.type).to eq('office')
    end

    it 'parses address information within places' do
      first_affiliation = affiliations.affiliations.first
      address = first_affiliation.place.first.address.first

      expect(address).to be_a(MaisPersonClient::Affiliations::Address)
      expect(address.type).to eq('office')
      expect(address.visibility).to eq('world')
      expect(address.city).to eq('Metro City')
      expect(address.state).to eq('California')
      expect(address.state_code).to eq('CA')
      expect(address.postal_code).to eq('90210-1234')
      expect(address.country).to eq('United States')
      expect(address.country_alpha2).to eq('US')
      expect(address.country_alpha3).to eq('USA')
      expect(address.country_numeric).to eq('840')
    end

    it 'parses multiple address lines' do
      first_affiliation = affiliations.affiliations.first
      address = first_affiliation.place.first.address.first

      expect(address.line).to be_an(Array)
      expect(address.line).to include('Department of Crime Detection')
      expect(address.line).to include('Mystery Building, 123 Sherlock Street, Room 221B')
      expect(address.line).to include('Gadget Lab, MC: 0007')
    end

    it 'parses telephone information within places' do
      first_affiliation = affiliations.affiliations.first
      telephones = first_affiliation.place.first.telephone

      expect(telephones).to be_an(Array)
      expect(telephones.length).to eq(3)

      office_phone = telephones.find { |tel| tel.number == '123-0007' }
      expect(office_phone).to be_a(MaisPersonClient::Affiliations::Telephone)
      expect(office_phone.type).to eq('office')
      expect(office_phone.visibility).to eq('world')
      expect(office_phone.icc).to eq('1')
      expect(office_phone.area).to eq('555')

      fax_phone = telephones.find { |tel| tel.type == 'officefax' }
      expect(fax_phone.number).to eq('123-0009')
    end
  end

  describe 'convenience methods' do
    describe '#faculty_affiliations' do
      it 'returns only faculty affiliations' do
        faculty_affs = affiliations.faculty_affiliations
        expect(faculty_affs.length).to eq(2) # one active faculty, one nonactive faculty
        expect(faculty_affs.all? { |aff| aff.type.include?('faculty') }).to be true
      end
    end

    describe '#student_affiliations' do
      it 'returns only student affiliations' do
        student_affs = affiliations.student_affiliations
        expect(student_affs.length).to eq(2) # both are nonactive students
        expect(student_affs.all? { |aff| aff.type.include?('student') }).to be true
      end
    end

    describe '#active_affiliations' do
      it 'returns only active affiliations (excludes nonactive)' do
        active_affs = affiliations.active_affiliations
        expect(active_affs.length).to eq(1) # only the current faculty affiliation
        expect(active_affs.none? { |aff| aff.type.include?('nonactive') }).to be true
      end
    end

    describe '#primary_affiliation' do
      it 'returns the affiliation with affnum 1' do
        primary = affiliations.primary_affiliation
        expect(primary.affnum).to eq('1')
        expect(primary.type).to eq('faculty')
        expect(primary.name).to eq('Faculty')
      end
    end

    describe '#org_ids' do
      it 'returns all adminid values' do
        expect(affiliations.org_ids).to contain_exactly('CRIME', 'TECH', 'SAFE')
      end
    end

    describe '#primary_org_id' do
      it 'returns the adminid for affiliation with affnum 1' do
        expect(affiliations.primary_org_id).to eq('CRIME')
      end
    end
  end

  describe 'struct definitions' do
    it 'defines all required struct classes' do
      expect(described_class::Department).to be_a(Class)
      expect(described_class::Organization).to be_a(Class)
      expect(described_class::AffData).to be_a(Class)
      expect(described_class::Address).to be_a(Class)
      expect(described_class::Telephone).to be_a(Class)
      expect(described_class::Place).to be_a(Class)
      expect(described_class::AffiliationRecord).to be_a(Class)
    end
  end

  describe 'edge cases' do
    context 'with minimal XML' do
      let(:minimal_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person card="123" name="Test User">
            <affiliation affnum="1" type="staff">Staff</affiliation>
          </Person>
        XML
      end
      let(:minimal_affiliations) { described_class.new(minimal_xml) }

      it 'handles missing optional elements gracefully' do
        affiliations_list = minimal_affiliations.affiliations
        expect(affiliations_list.length).to eq(1)

        aff = affiliations_list.first
        expect(aff.affnum).to eq('1')
        expect(aff.type).to eq('staff')
        expect(aff.name).to eq('Staff')
        expect(aff.department).to be_nil
        expect(aff.description).to be_nil
        expect(aff.affdata).to be_empty
        expect(aff.place).to be_empty
      end
    end

    context 'with malformed XML' do
      let(:malformed_xml) { '<Person><invalid>' }

      it 'still parses what it can' do
        expect { described_class.new(malformed_xml) }.not_to raise_error
      end
    end

    context 'when primary_org_id and affiliation 1 is missing' do
      let(:no_aff1_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Person card="999" name="No Aff1">
            <affiliation affnum="2" type="staff"><department><organization adminid="NOPE">Org</organization></department></affiliation>
          </Person>
        XML
      end

      let(:no_aff1_affiliations) { described_class.new(no_aff1_xml) }

      it 'returns nil for primary_org_id when affnum=1 is absent' do
        expect(no_aff1_affiliations.primary_org_id).to be_nil
      end
    end
  end
end
