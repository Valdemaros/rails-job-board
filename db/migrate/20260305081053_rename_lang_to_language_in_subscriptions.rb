class RenameLangToLanguageInSubscriptions < ActiveRecord::Migration[8.1]
  def change
    rename_column :subscriptions, :lang, :language
  end
end
