class LocationAsset < ApplicationRecord
  belongs_to :location
  belongs_to :customer
  has_many :fault_events
end
