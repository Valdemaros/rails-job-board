class Vacancy < ApplicationRecord
  validates :name, presence: true
  validates :hh_id, presence: true

  validates :hh_id, uniqueness: true
  
  validates :salary_from, numericality: { greater_than: 0, allow_nil: true }
  validates :salary_to,   numericality: { greater_than: 0, allow_nil: true } 

end



