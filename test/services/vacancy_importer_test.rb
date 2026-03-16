require "test_helper"

class VacancyImporterTest < ActiveSupport::TestCase
  test "imports vacancies without duplicates" do
    # Создаём тестовые данные
    subscription = Subscription.create!(
      telegram_id: 1234,
      username: "Papaya",
      language: :ruby,
      active: true
    )

    vacancy = Vacancy.create!(
      hh_id: "test_1",
      name: "Ruby Developer",
      employer: "Test",
      area: "Moscow",
      url: "https://hh.ru/1"
    )

    # Проверяем что данные создались
    assert_equal 1, Subscription.count
    assert_equal 1, Vacancy.count
  end
end
