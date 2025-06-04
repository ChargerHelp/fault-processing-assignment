class CreateFaultEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :fault_events do |t|
      t.integer :id_from_source
      t.references :customer, null: false, foreign_key: true
      t.references :location_asset, null: false, foreign_key: true
      t.integer :connector_id
      t.datetime :fault_time
      t.datetime :resolved_at
      t.string :status
      t.string :downtime_type
      t.string :fault_type
      t.string :source
      t.boolean :is_alarm
      t.datetime :processed_at
      t.text :actions_taken

      t.timestamps
    end
  end
end
