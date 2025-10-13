# frozen_string_literal: true

class MaisPersonClient
  # Model for a Person from the MAIS Person API
  class Person
    HOME_ADDRESS_TYPES = %w[home permanent].freeze

    # Struct definitions for complex nodes
    PersonName = Struct.new(:type, :visibility, :full_name, :first_name, :first_nval, :middle, :middle_nval,
                            :last, :last_nval)
    Address = Struct.new(:type, :visibility, :full_address, :line, :city, :state, :state_code, :postal_code, :country,
                         :country_alpha2, :country_alpha3, :country_numeric, :affnum)
    Telephone = Struct.new(:type, :visibility, :full_number, :icc, :area, :number, :affnum)
    Email = Struct.new(:type, :visibility, :full_email, :user, :host)
    Url = Struct.new(:type, :visibility, :url)
    Location = Struct.new(:code, :type, :visibility, :location)
    Identifier = Struct.new(:type, :visibility, :nval, :value)
    Department = Struct.new(:affnum, :name, :organization, :adminid, :level2orgid, :level2orgname, :regid)
    Affiliation = Struct.new(:affnum, :effective, :organization, :type, :visibility, :name, :department, :description,
                             :affdata, :place)
    AffData = Struct.new(:affnum, :type, :code, :value)
    Place = Struct.new(:type, :affnum, :address, :qbfr, :telephone)
    EmergencyContact = Struct.new(:number, :primary, :sync_permanent, :visibility, :contact_name,
                                  :contact_relationship, :contact_relationship_code, :contact_telephones,
                                  :contact_address)

    attr_reader :xml

    def initialize(xml)
      @xml = Nokogiri::XML(xml)
      @xml.remove_namespaces!
    end

    # Root attributes
    def card
      xml.root['card']
    end

    def listing
      xml.root['listing']
    end

    def name_attr
      xml.root['name']
    end

    def regid
      xml.root['regid']
    end

    def relationship
      xml.root['relationship']
    end

    def source
      xml.root['source']
    end

    def sunetid
      xml.root['sunetid']
    end

    def univid
      xml.root['univid']
    end

    def stanford_end_date
      value = xml.root['stanfordenddate']
      return nil unless value

      stripped = value.strip
      stripped.empty? ? nil : stripped
    end

    # Names (multiple possible)
    def names
      xml.xpath('//name').map { |name_node| build_person_name(name_node) }
    end

    def registered_name
      names.find { |name| name.type == 'registered' }
    end

    def display_name
      names.find { |name| name.type == 'display' }
    end

    # Name component helpers
    def first_name
      registered_name&.first_name
    end

    def middle_name
      registered_name&.middle
    end

    def last_name
      registered_name&.last
    end

    # Titles (multiple possible)
    def titles
      xml.xpath('//title').map do |title_node|
        {
          type: title_node['type'],
          visibility: title_node['visibility'],
          title: title_node.text
        }
      end
    end

    def job_title
      titles.find { |title| title[:type] == 'job' }&.[](:title)
    end

    # Biodemo
    def gender
      xml.at_xpath('//biodemo/gender')&.text
    end

    def biodemo_visibility
      xml.at_xpath('//biodemo')&.[]('visibility')
    end

    # Addresses (multiple possible)
    def addresses
      xml.xpath('//address').map { |addr_node| build_address(addr_node) }
    end

    # Telephones (multiple possible)
    def telephones
      xml.xpath('//telephone').map { |tel_node| build_telephone(tel_node) }
    end

    # Emails (multiple possible)
    def emails
      xml.xpath('//email').map do |email_node|
        Email.new(
          email_node['type'],
          email_node['visibility'],
          email_node.children.first&.text&.strip,
          email_node.at_xpath('user')&.text,
          email_node.at_xpath('host')&.text
        )
      end
    end

    def primary_email
      emails.find { |email| email.type == 'primary' }&.full_email
    end

    # URLs (multiple possible)
    def urls
      xml.xpath('//url').map do |url_node|
        Url.new(
          url_node['type'],
          url_node['visibility'],
          url_node.text
        )
      end
    end

    def homepage
      urls.find { |url| url.type == 'homepage' }&.url
    end

    # Locations (multiple possible)
    def locations
      xml.xpath('//location').map do |loc_node|
        Location.new(
          loc_node['code'],
          loc_node['type'],
          loc_node['visibility'],
          loc_node.text
        )
      end
    end

    # Places (multiple possible - home, work, etc.)
    def places
      xml.xpath('//place').map { |place_node| build_place(place_node) }
    end

    # Affiliations (multiple possible)
    def affiliations
      xml.xpath('//affiliation').map { |aff_node| build_affiliation(aff_node) }
    end

    # returns the primary role/type for the person (from affiliation with affnum 1)
    def primary_role
      affiliations.find { |aff| aff.affnum == '1' }&.type
    end

    # returns the org_id for the primary affiliation (affnum == '1')
    def primary_org_code
      # Find the affiliation with affnum == '1' and return the department's organization adminid
      aff = affiliations.find { |a| a.affnum == '1' }
      return nil unless aff

      # department may be nil; department.adminid holds the org code
      aff.department&.adminid
    end

    # returns the effective_date for the primary affiliation (affnum == '1')
    def primary_effective_date
      # Find the affiliation with affnum == '1' and return the effective date
      aff = affiliations.find { |a| a.affnum == '1' }
      return nil unless aff

      # effective date
      aff.effective
    end

    # indicates if a person is a member of the academic council
    def academic_council?
      # If there are no affiliations, the person is not a member of the academic council
      return false if affiliations.empty?

      affiliations.any? do |affiliation|
        affiliation.affdata.any? do |affdata|
          affdata.type == 'academic_council' && affdata.value&.downcase == 'member of academic council'
        end
      end
    end

    # Identifiers (multiple)
    def identifiers
      xml.xpath('//identifier').map do |id_node|
        Identifier.new(
          id_node['type'],
          id_node['visibility'],
          id_node['nval'],
          id_node.text
        )
      end
    end

    def identifier_by_type(type)
      identifiers.find { |id| id.type == type }&.value
    end

    # Privacy groups
    def privgroups
      xml.xpath('//privgroup').map(&:text)
    end

    # eduPerson attributes
    def eduperson_primary_affiliation
      xml.at_xpath('//edupersonprimaryaffiliation')&.text
    end

    def eduperson_affiliations
      xml.xpath('//edupersonaffiliation').map(&:text)
    end

    # Emergency contacts
    def emergency_contacts
      xml.xpath('//emergency_contact').map { |contact_node| build_emergency_contact(contact_node) }
    end

    # Convenience methods for common lookups
    def work_address
      addresses.find { |addr| addr.type == 'work' }
    end

    def home_address
      addresses.find { |addr| HOME_ADDRESS_TYPES.include?(addr.type) }
    end

    def work_phone
      telephones.find { |tel| tel.type == 'work' }
    end

    def mobile_phone
      telephones.find { |tel| tel.type == 'mobile' }
    end

    def orcid
      identifier_by_type('orcid')
    end

    def directory_id
      identifier_by_type('directory')
    end

    private

    def build_person_name(name_node)
      PersonName.new(
        name_node['type'],
        name_node['visibility'],
        name_node.children.first&.text&.strip,
        name_node.at_xpath('first')&.text,
        name_node.at_xpath('first')&.[]('nval'),
        name_node.at_xpath('middle')&.text,
        name_node.at_xpath('middle')&.[]('nval'),
        name_node.at_xpath('last')&.text,
        name_node.at_xpath('last')&.[]('nval')
      )
    end

    def build_address(addr_node)
      lines = addr_node.xpath('line').map(&:text)
      Address.new(
        addr_node['type'],
        addr_node['visibility'],
        addr_node.children.first&.text&.strip,
        lines.length == 1 ? lines.first : lines,
        addr_node.at_xpath('city')&.text,
        addr_node.at_xpath('state')&.text,
        addr_node.at_xpath('state')&.[]('code'),
        addr_node.at_xpath('postalcode')&.text,
        addr_node.at_xpath('country')&.text,
        addr_node.at_xpath('country')&.[]('alpha2'),
        addr_node.at_xpath('country')&.[]('alpha3'),
        addr_node.at_xpath('country')&.[]('numeric'),
        addr_node['affnum']
      )
    end

    def build_telephone(tel_node)
      Telephone.new(
        tel_node['type'],
        tel_node['visibility'],
        tel_node.children.first&.text&.strip,
        tel_node.at_xpath('icc')&.text,
        tel_node.at_xpath('area')&.text,
        tel_node.at_xpath('number')&.text,
        tel_node['affnum']
      )
    end

    def build_department(dept_node)
      return nil unless dept_node

      org_node = dept_node.at_xpath('organization')
      Department.new(
        dept_node['affnum'],
        dept_node.children.first&.text&.strip,
        org_node&.text,
        org_node&.[]('adminid'),
        org_node&.[]('level2orgid'),
        org_node&.[]('level2orgname'),
        org_node&.[]('regid')
      )
    end

    def build_affdata_array(aff_node)
      aff_node.xpath('affdata').map do |data_node|
        AffData.new(
          data_node['affnum'],
          data_node['type'],
          data_node['code'],
          data_node.text
        )
      end
    end

    def build_places_for_affiliation(aff_node)
      aff_node.xpath('place').map { |place_node| build_place(place_node) }
    end

    def build_place(place_node)
      place_addresses = place_node.xpath('address').map { |addr_node| build_address(addr_node) }
      place_telephones = place_node.xpath('telephone').map { |tel_node| build_telephone(tel_node) }

      Place.new(
        place_node['type'],
        place_node['affnum'],
        place_addresses,
        place_node.at_xpath('qbfr')&.text,
        place_telephones
      )
    end

    def build_emergency_contact_telephones(contact_node)
      contact_node.xpath('contact_telephone').map do |tel_node|
        Telephone.new(
          tel_node['type'],
          tel_node['visibility'],
          tel_node.children.first&.text&.strip,
          tel_node.at_xpath('icc')&.text,
          tel_node.at_xpath('area')&.text,
          tel_node.at_xpath('number')&.text,
          nil
        )
      end
    end

    def build_emergency_contact_address(contact_node)
      addr_node = contact_node.at_xpath('contact_address')
      return nil unless addr_node

      build_address(addr_node)
    end

    def build_affiliation(aff_node)
      department = build_department(aff_node.at_xpath('department'))
      affdata = build_affdata_array(aff_node)
      aff_places = build_places_for_affiliation(aff_node)

      Affiliation.new(
        aff_node['affnum'],
        aff_node['effective'],
        aff_node['organization'],
        aff_node['type'],
        aff_node['visibility'],
        aff_node.children.first&.text&.strip,
        department,
        aff_node.at_xpath('description')&.text,
        affdata,
        aff_places
      )
    end

    def build_emergency_contact(contact_node)
      contact_telephones = build_emergency_contact_telephones(contact_node)
      contact_address = build_emergency_contact_address(contact_node)
      rel_node = contact_node.at_xpath('contact_relationship')

      EmergencyContact.new(
        contact_node['number'],
        contact_node['primary'] == 'true',
        contact_node['sync_permanent'] == 'true',
        contact_node['visibility'],
        contact_node.at_xpath('contact_name')&.text,
        rel_node&.text,
        rel_node&.[]('code'),
        contact_telephones,
        contact_address
      )
    end
  end
end
