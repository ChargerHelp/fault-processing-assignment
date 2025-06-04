class Location < ApplicationRecord
  belongs_to :customer
  has_many :location_assets
  has_many :fault_events, through: :location_assets
end
