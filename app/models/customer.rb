class Customer < ApplicationRecord
  has_many :locations
  has_many :location_assets
  has_many :fault_events
end
