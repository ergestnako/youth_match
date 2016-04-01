require_relative './resource'

class ICIMS::Person < ICIMS::Resource

  attr_reader :id, :status, :interests, :workflows, :preference, :addresses

  def initialize(id: , status: , interests: , transit_pass: , preference: , addresses: )
    @id           = id
    @status       = status
    @interests    = process_interests(interests)
    @transit_pass = transit_pass
    @preference   = preference
    @addresses    = addresses
  end

  def address
    ICIMS::Address.new(@addresses).to_s
  end

  def workflows
    @workflows ||= ICIMS::Workflow.where(person: self.id)
  end

  def prefers_nearby
    @preference == "Close to me"
  end

  def prefers_interest
    !prefers_nearby?
  end

  def transit_pass
    @transit_pass == "Yes"
  end

  alias_method :prefers_nearby?, :prefers_nearby
  alias_method :prefers_interest?, :prefers_interest
  alias_method :transit_pass?, :transit_pass

  def self.find(id)
    response = get("/people/#{id}?fields=#{fields}", headers: headers)
    handle response do |r|
      self.new(id: id, status: 'lol', interests: r['field23848'],
        transit_pass: r['field36999'], preference: r['field29946'],
        addresses: r['addresses'])
    end
  end

  private

  def process_interests(interests)
    Array(interests).flat_map { |i| CategorySplitter.split(i['formattedvalue']) }
  end

  def self.fields
        # interests, location, T pass
    %w( field29946 field23848 field36999 addresses ).join(',')
  end

end
