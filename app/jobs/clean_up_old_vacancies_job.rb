class CleanUpOldVacanciesJob < ApplicationJob
  
  def perform(days_old: 30)
    delete_old_records(days_old)
    log_result
  end

  private

  def delete_old_records(days)
    @deleted = Vacancy.where("published_at < ?", days.days.ago).delete_all
  end

  def log_result
    Rails.logger.info "Deleted #{@deleted}old vacancies"
  end

end
