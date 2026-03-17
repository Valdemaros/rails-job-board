require "test_helper"

class CleanUpOldVacanciesJobTest < ActiveSupport::TestCase
  test "clean_up_db" do
    old_vacancy = Vacancy.create!(
      hh_id: "123412",
      name: "Ruby on Rails Developer",
      published_at: 40.days.ago
    )

    new_vacancy = Vacancy.create!(
      hh_id: "2352323",
      name: "Elixir Developer",
      published_at: 12.days.ago
    )

    assert_equal 2, Vacancy.count

    CleanUpOldVacanciesJob.new.perform(days_old: 30)

    assert_equal 1, Vacancy.count
    assert Vacancy.exists?(new_vacancy.id)
    refute Vacancy.exists?(old_vacancy.id)
  end

  # test "keeps_all_vacancies_when_days_old_is 0" do
  #   Vacancy.create!(hh_id:"2131234", name:"Guppi", published_at: 1.day.ago)
  #   CleanUpOldVacanciesJob.new.perform(days_old: 0)
  #   assert_equal 1, Vacancy.count
  # end

end

