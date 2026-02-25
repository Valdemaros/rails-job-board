class CreateVacancies < ActiveRecord::Migration[8.1]
  def change
    create_table :vacancies do |t|
      t.string :hh_id
      t.string :name
      
      t.string :area
      t.string :employer
      t.string :experience
      t.string :url
      t.integer :salary_from
      t.integer :salary_to
      t.datetime :published_at
      t.text :snippet

      t.timestamps
    end

    add_index :vacancies, :hh_id, unique: true
  end
end
