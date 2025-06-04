class AddProcessingAttributesToFaultEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :fault_events, :urgency_level, :string
    add_column :fault_events, :response_time_hours, :integer
    add_column :fault_events, :station_wide, :boolean
  end
end
