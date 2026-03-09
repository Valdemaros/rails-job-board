
require "test_helper"

class VacancyTest < ActiveSupport::TestCase
  setup do
    Vacancy.delete_all
  end

  test "nil" do
    vacancy = Vacancy.new(name: nil)
    assert_not vacancy.valid?
  end

  test "hh_id" do
    vacancy = Vacancy.new(hh_id: nil)
    assert_not vacancy.valid?
  end

  test "hh_id_uniq" do
    vacancy = Vacancy.create!(name: "Piy", hh_id: "21")
    duplicate = Vacancy.new(name: "Piy_2", hh_id: "21")
    assert_not duplicate.valid?
  end
end
