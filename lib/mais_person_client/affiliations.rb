# frozen_string_literal: true

class MaisPersonClient
  # Model for Affiliations from the MAIS Person API
  class Affiliations
    # Struct definitions for complex nodes
    Department = Struct.new(:affnum, :name, :organization)
    Organization = Struct.new(:acadid, :adminid, :level2orgid, :level2orgname, :regid, :name)
    AffData = Struct.new(:affnum, :type, :code, :value)
    Address = Struct.new(:affnum, :type, :visibility, :full_address, :line, :city, :state, :state_code,
                         :postal_code, :country, :country_alpha2, :country_alpha3, :country_numeric)
    Telephone = Struct.new(:affnum, :type, :visibility, :full_number, :icc, :area, :number)
    Place = Struct.new(:affnum, :type, :address, :telephone)
    AffiliationRecord = Struct.new(:affnum, :effective, :organization, :type, :visibility, :name,
                                   :department, :description, :affdata, :place)

    attr_reader :xml

    def initialize(xml)
      @xml = Nokogiri::XML(xml)
      @xml.remove_namespaces!
    end

    # Root person attributes
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

    # Affiliations (multiple possible)
    def affiliations
      xml.xpath('//affiliation').map { |aff_node| build_affiliation(aff_node) }
    end

    # Convenience methods
    def faculty_affiliations
      affiliations.select { |aff| aff.type&.include?('faculty') }
    end

    def student_affiliations
      affiliations.select { |aff| aff.type&.include?('student') }
    end

    def active_affiliations
      affiliations.reject { |aff| aff.type&.include?('nonactive') }
    end

    def primary_affiliation
      affiliations.find { |aff| aff.affnum == '1' }
    end

    def org_ids
      xml.xpath('//organization/@adminid').map(&:value).uniq.compact
    end

    def primary_org_code
      org_node = xml.at_xpath("//affiliation[@affnum='1']//organization")
      org_node ? org_node['adminid'] : nil
    end

    private

    def build_affiliation(aff_node)
      department = build_department(aff_node.at_xpath('department'))
      affdata = build_affdata_array(aff_node)
      places = build_places_for_affiliation(aff_node)

      AffiliationRecord.new(
        aff_node['affnum'],
        aff_node['effective'],
        aff_node['organization'],
        aff_node['type'],
        aff_node['visibility'],
        aff_node.children.first&.text&.strip,
        department,
        aff_node.at_xpath('description')&.text,
        affdata,
        places
      )
    end

    def build_department(dept_node)
      return nil unless dept_node

      org_node = dept_node.at_xpath('organization')
      organization = build_organization(org_node) if org_node

      Department.new(
        dept_node['affnum'],
        dept_node.children.first&.text&.strip,
        organization
      )
    end

    def build_organization(org_node)
      return nil unless org_node

      Organization.new(
        org_node['acadid'],
        org_node['adminid'],
        org_node['level2orgid'],
        org_node['level2orgname'],
        org_node['regid'],
        org_node.text&.gsub(/\s+/, ' ')&.strip
      )
    end

    def build_affdata_array(aff_node)
      aff_node.xpath('affdata').map do |data_node|
        AffData.new(
          data_node['affnum'],
          data_node['type'],
          data_node['code'],
          data_node.text&.strip
        )
      end
    end

    def build_places_for_affiliation(aff_node)
      aff_node.xpath('place').map { |place_node| build_place(place_node) }
    end

    def build_place(place_node)
      addresses = place_node.xpath('address').map { |addr_node| build_address(addr_node) }
      telephones = place_node.xpath('telephone').map { |tel_node| build_telephone(tel_node) }

      Place.new(
        place_node['affnum'],
        place_node['type'],
        addresses,
        telephones
      )
    end

    def build_address(addr_node)
      lines = addr_node.xpath('line').map { |line| line.text&.gsub(/\s+/, ' ')&.strip }
      Address.new(
        addr_node['affnum'],
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
        addr_node.at_xpath('country')&.[]('numeric')
      )
    end

    def build_telephone(tel_node)
      Telephone.new(
        tel_node['affnum'],
        tel_node['type'],
        tel_node['visibility'],
        tel_node.children.first&.text&.strip,
        tel_node.at_xpath('icc')&.text&.strip,
        tel_node.at_xpath('area')&.text&.strip,
        tel_node.at_xpath('number')&.text&.strip
      )
    end
  end
end
