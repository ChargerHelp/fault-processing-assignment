#!/usr/bin/env ruby
require_relative '../config/environment'

# Get the first customer and asset for testing
customer = Customer.first
asset = LocationAsset.first

if customer.nil? || asset.nil?
  puts "Run 'rails db:seed' first to create test data"
  exit 1
end

fault_event_data = {
  id_from_source: 19824588,
  customer_id: customer.id,
  location_asset_id: asset.id,
  connector_id: 2,
  fault_time: "2025-06-04T14:53:13.000Z",
  resolved_at: nil,
  status: "NEEDS SERVICE",
  downtime_type: "NEEDS SERVICE",
  fault_type: "Ground Fault Circuit Interrupter",
  source: "chargepoint",
  is_alarm: true
}

puts "Testing with:"
puts "Customer: #{customer.name} (SLA: #{customer.sla_hours}h)"
puts "Asset: #{asset.name}"
puts "Fault: #{fault_event_data[:fault_type]} - #{fault_event_data[:status]}"
puts "\nSending POST to /api/v1/fault_events..."

# Make the API call
require 'net/http'
require 'json'

uri = URI('http://localhost:3000/api/v1/fault_events')
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
request.body = fault_event_data.to_json

response = http.request(request)
puts "Response: #{response.code} - #{response.body}"
