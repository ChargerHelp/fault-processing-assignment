class CreateLocationAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :location_assets do |t|
      t.string :name
      t.references :location, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
