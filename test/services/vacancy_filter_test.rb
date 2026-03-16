require "test_helper"

class VacancyFilterTest < ActiveSupport::TestCase
  test "unknown_language" do
    vacancies = []
    assert_raises(ArgumentError) do
      filtered = VacancyFilter.new(vacancies, language: :elixir)
    end
  end

  test "vacancies_empty" do
    vacancies = []
    filtered = VacancyFilter.new(vacancies, language: :ruby).call
    assert_empty filtered
  end

  test "should_accept_all_supported_languages" do
    vacancies = []
    languages = %i[ruby python java javascript go php]

    languages.each do |lang|
      assert_nothing_raised do
        VacancyFilter.new(vacancies, language: lang)
      end
    end
  end

  test "should_filter_old_vacancies" do
    vacancies = [
      { "name" => "rubyonrails", "published_at" => Time.zone.now.to_s },
      { "name" => "python", "published_at" => 20.days.ago.to_s },
      { "name" => "php", "published_at" => 15.days.ago.to_s },
      { "name" => "java", "published_at" => 13.days.ago.to_s }
    ]
    ruby_filtered = VacancyFilter.new(vacancies, language: :ruby).call
    assert_equal 1, ruby_filtered.count
    java_filtered = VacancyFilter.new(vacancies, language: :java).call
    assert_equal 1, java_filtered.count
    python_filtered = VacancyFilter.new(vacancies, language: :python).call
    assert_equal 0, python_filtered.count
    php_filtered = VacancyFilter.new(vacancies, language: :php).call
    assert_equal 0, php_filtered.count
  end
end
