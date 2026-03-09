class ChangeLanguageTypeInSubscriptions < ActiveRecord::Migration[8.1]
  def change
    remove_column :subscriptions, :language
    add_column :subscriptions, :language, :integer, default: 0, null: false
    add_index :subscriptions, :language
  end
end
