# Как работает:
# 1. Отправляет GET-запросы к API HH.ru (/vacancies)
# 2. Получает вакансии постранично (пагинация)
# 3. Возвращает сырой массив данных (JSON)
#
class HhScraper
  BASE_URL = "https://api.hh.ru"

  LANGUAGES = %w[Ruby Golang Java JavaScript PHP Python].freeze

  def initialize(per_page: 100, max_pages: 5)
    @per_page = per_page
    @max_pages = max_pages
  end

  def fetch_all_languages
    LANGUAGES.flat_map { |language| fetch_for_language(language) }
  end

  private

  def fetch_for_language(language)
    vacancies = []
    page = 0

    loop do
      # Получаем страницу с данными
      data = fetch_page_raw(language, page)
      items = data["items"] || []
      vacancies.concat(items)

      page += 1
      total_pages = data["pages"].to_i

      # Выход из цикла если страницы закончились или достигнут лимит
      break if page >= total_pages
      break if page >= @max_pages
    end

    vacancies
  end


  def fetch_page_raw(language, page)
    params = {
      text: language,
      per_page: @per_page,
      page: page,
      order_by: "publication_time"
    }

    # GET-запрос к /vacancies с параметрами
    response = connection.get("/vacancies", params)

    # Обработка ошибок API
    unless response.success?
      Rails.logger.error("HH error: #{response.status} #{response.body}")
      return { "items" => [], "pages" => 0 }
    end

    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |conn|
      conn.headers["HH-User-Agent"] = "your-app-name/1.0 (kuzmenkov.vova2@gmail)"
      conn.headers["Accept"] = "application/json"
    end
  end
end
