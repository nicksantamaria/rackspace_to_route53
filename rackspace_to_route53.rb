require 'fog'
require 'pp'
require 'yaml'

config = YAML.load_file(File.dirname(File.expand_path(__FILE__)) << "/settings.yml")

DOMAINS = config['domains']
RACKSPACE = {
  :provider => 'Rackspace',
  :rackspace_api_key => config['rackspace']['key'],
  :rackspace_username => config['rackspace']['username']
}

R53 = {
  :provider => 'AWS',
  :aws_access_key_id => config['aws']['id'],
  :aws_secret_access_key => config['aws']['secret']
}

class Provider
  def initialize(connection_spec)
    @connection = Fog::DNS.new(connection_spec)
  end

  def get_records(domain,types=nil)
    records = %w()
    get_domain(domain).records.each do |record|
      if types.nil? or types.include? record.type
        records.push(record)
      end
    end
    return records
  end

  def get_domain(domain)
    @connection.zones.select{|z| z.domain == domain  or z.domain == add_dot(domain)}[0]
  end

  def create_zone(domain)
    unless get_domain(domain)
      @connection.zones.create(:domain => domain)
    end
  end

  def new_record(domain,name,value,ttl,type)
    name = name.downcase
    # some of the rackspace entries had uppercase but when added to R53 it went to downcase.
    existing =  get_records(domain,[type]).select{|r| add_dot(name) == r.name}
    unless existing.empty?
      puts "#{name} => #{value} (#{type}) EXISTS"
      return
    end
    puts "#{name} => #{value} (#{type})"
    record = {
      :name => name,
      :value => value,
      :ttl => ttl,
      :type => type
    }
    get_domain(domain).records.create(record)
  end

  def add_dot(s)
    return s if s[-1] == '.'
    "#{s}."
  end
end

def migrate(domain)
  puts "MIGRATING #{domain}"
  r53 = Provider.new(R53)
  rs = Provider.new(RACKSPACE)

  r53.create_zone domain
  rs.get_records(domain, ["CNAME", "A", "AAAA"]).each do |record|
    r53.new_record(domain, record.name, record.value, record.ttl, record.type)
  end
  rs.get_records(domain,["TXT"]).group_by{|r| r.name}.each_pair do |name,records|
    texts = records.map(&:value)
    texts.map!{|t| "\"#{t}\""}
    r53.new_record(domain, name, texts , records[0].ttl, "TXT")
  end
  rs.get_records(domain,["MX"]).group_by{|r| r.name}.each_pair do |name,records|
    entries = records.map{|r| "#{r.priority} #{r.value}."}
    r53.new_record(domain, name, entries , records[0].ttl, "MX")
  end
end

DOMAINS.each do |d|
  migrate d
end
