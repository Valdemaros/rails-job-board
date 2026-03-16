# VacancyFilter — фильтрует сырые вакансии от HH.ru
class VacancyFilter
  KEYWORDS_BY_LANGUAGE = {
    ruby: %w[ruby rails rubyonrails],
    python: %w[python django flask fastapi],
    java: %w[java spring j2ee springboot],
    go: %w[golang golangdeveloper],
    javascript: %w[javascript typescript react nodejs vue angular],
    php: %w[php laravel symfony]
  }.freeze

  STOP_WORDS = %w[
    менеджер менеджером hr маркетолог seo smm
    дизайнер дизайнером аналитик тестировщик qa
    продакт продакт-менеджер project manager
    директор руководитель начальник
  ].freeze

  VACANCY_MAX_AGE_DAYS = 14

  def initialize(vacancies, language:)
    @vacancies = vacancies
    @language = language
    @keywords = KEYWORDS_BY_LANGUAGE[language]

    # Выбрасываем ошибку если язык не найден в маппинге
    raise ArgumentError, "Unknown language: | #{language}" if @keywords.nil?
  end

  def call
    @vacancies.select { |vacancy| relevant?(vacancy) }
  end

  private

  # Проверяет что вакансия релевантна (дата + ключевые слова + нет стоп-слов)
  def relevant?(vacancy)
    date_fresh?(vacancy) && keyword_match?(vacancy) && !stop_words_match?(vacancy)
  end

  def date_fresh?(vacancy)
    published_at_str = vacancy["published_at"]
    return false if published_at_str.blank?

    # Парсим дату публикации (ISO 8601)
    published_at = Time.zone.parse(published_at_str) rescue nil
    return false if published_at.blank?

    # Сравниваем с текущей датой
    published_at >= VACANCY_MAX_AGE_DAYS.days.ago
  end

  def keyword_match?(vacancy)
    name = vacancy["name"].to_s.downcase
    @keywords.any? { |keyword| name.include?(keyword.downcase) }
  end

  def stop_words_match?(vacancy)
    name = vacancy["name"].to_s.downcase
    STOP_WORDS.any? { |stop_word| name.include?(stop_word) }
  end
end
