class FetchAllVacanciesJob < ApplicationJob
  LANGUAGES = [:ruby, :python, :java, :go, :javascript, :php]

  def perform
    raw_vacancies = HhScraper.new.fetch_all_languages

    LANGUAGES.each do |language|
      filtered = VacancyFilter.new(raw_vacancies, language: language).call
      imported = VacancyImporter.new.import(filtered)
      Rails.logger.info ">>> #{language}: imported #{imported.size} vacancies"
    end
  end
end
