class Subscription < ApplicationRecord
  validates :telegram_id, presence: true
  validates :username, presence: true
  validates :language, presence: true

  validates :telegram_id, uniqueness: true

  # Rails 8 использует новый синтаксис enum
  enum :language, [ :ruby, :python, :java, :go, :javascript, :php ], prefix: true
end
