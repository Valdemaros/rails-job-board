class FetchVacanciesJob
  include Sidekiq::Job

  def perform
    Rails.logger.info ">>> FetchVacanciesJob run at #{Time.current}"
   
    raw_vacancies = HhScraper.new.fetch_for_query
    Rails.logger.info ">>> HhScraper returned #{raw_vacancies.size} vacancies"

    filtered_vacancies = VacancyFilter.new(raw_vacancies).call
    Rails.logger.info ">>>VacancyFilter left #{filtered_vacancies.size}"
    
    imported_vacancies = VacancyImporter.new.import(filtered_vacancies)
    Rails.logger.info ">>>VacancyImporter imported #{imported_vacancies.size}"
    
    Rails.logger.info ">>> FetchVacanciesJob finished at #{Time.current}"
  rescue => e
    Rails.logger.error ">>> FetchVacanciesJob FAILED: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e  
  end
end

