class FetchVacanciesJob < ApplicationJob
  queue_as :default

  def perform(language)
    Rails.logger.info ">>> FetchVacanciesJob run at #{Time.current}"

    # 1. Парсим HH.ru
    raw_vacancies = HhScraper.new.fetch_all_languages
    Rails.logger.info ">>> HhScraper returned #{raw_vacancies.size} vacancies"

    # 2. Фильтруем по дате и ключевым словам
    filtered_vacancies = VacancyFilter.new(raw_vacancies, language: language).call
    Rails.logger.info ">>> VacancyFilter left #{filtered_vacancies.size}"

    # 3. Сохраняем в БД (без дубликатов)
    imported_vacancies = VacancyImporter.new.import(filtered_vacancies)
    Rails.logger.info ">>> VacancyImporter imported #{imported_vacancies.size}"

    # 4. Отправляем уведомления подписчикам
    if imported_vacancies.any?
      # Если есть новые — отправляем их
      TelegramNotifier.new(language: language).send_vacancies(imported_vacancies)
      Rails.logger.info ">>> TelegramNotifier sent #{imported_vacancies.size} new vacancies"
    else
      # Если новых нет — отправляем последние 5 из БД
      recent_vacancies = Vacancy.where("name ILIKE ?", "%#{language}%").order(created_at: :desc).limit(5)
      if recent_vacancies.any?
        TelegramNotifier.new(language: language).send_vacancies(recent_vacancies)
        Rails.logger.info ">>> TelegramNotifier sent 5 recent vacancies (no new)"
      else
        Rails.logger.info ">>> No vacancies to send"
      end
    end

    Rails.logger.info ">>> FetchVacanciesJob finished at #{Time.current}"
  rescue => e
    Rails.logger.error ">>> FetchVacanciesJob FAILED: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
