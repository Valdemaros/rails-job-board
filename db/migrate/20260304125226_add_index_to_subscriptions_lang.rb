class AddIndexToSubscriptionsLang < ActiveRecord::Migration[8.1]
  def change
    add_index :subscriptions, :lang
  end
end
