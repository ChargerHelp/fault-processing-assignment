# Create test customers with different SLAs
customer_107 = Customer.create!(name: "Fast Response Corp", sla_hours: 2)
customer_261 = Customer.create!(name: "Standard Service LLC", sla_hours: 4)

# Create locations
location_1 = Location.create!(name: "Downtown Station", customer: customer_107)
location_2 = Location.create!(name: "Mall Charging Hub", customer: customer_261)

# Create assets
asset_12920 = LocationAsset.create!(name: "Station A", location: location_1, customer: customer_107)
asset_56828 = LocationAsset.create!(name: "Station B", location: location_2, customer: customer_261)

puts "Created customers:"
puts "- #{customer_107.name} (ID: #{customer_107.id}, SLA: #{customer_107.sla_hours}h)"
puts "- #{customer_261.name} (ID: #{customer_261.id}, SLA: #{customer_261.sla_hours}h)"
puts "Created assets:"
puts "- #{asset_12920.name} (ID: #{asset_12920.id}) at #{location_1.name}"
puts "- #{asset_56828.name} (ID: #{asset_56828.id}) at #{location_2.name}"
