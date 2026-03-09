class AddLangToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :lang, :string
  end
end
