class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.bigint :telegram_id
      t.string :username
      t.boolean :active

      t.timestamps
    end
    add_index :subscriptions, :telegram_id, unique: true
  end
end
