# Как работает:
# 1. Отправляет GET-запросы к API HH.ru (/vacancies)
# 2. Получает вакансии постранично (пагинация)
# 3. Возвращает сырой массив данных (JSON)
#
class HhScraper
  BASE_URL = 'https://api.hh.ru'

  languages = %w(Ruby Go Java Javascript PHP Python).freeze

  # @param query [String] поисковый запрос (например, "Ruby", "Python")
  # @param per_page [Integer] количество вакансий на странице (максимум 100 по API HH)
  # @param max_pages [Integer] ограничение на количество страниц для парсинга
  #               (защита от слишком долгих запросов)
  def initialize(query: "Ruby", per_page: 100, max_pages: 5)
    @query = query
    @per_page = per_page
    @max_pages = max_pages
  end

  # Основной метод — fetch_for_query
  # Возвращает массив сырых вакансий (Hash) для переданного query
  #
  # Алгоритм:
  # 1. Инициализирует пустой массив vacancies
  # 2. В цикле запрашивает страницы по одной (page 0, 1, 2...)
  # 3. Добавляет вакансии из каждой страницы в общий массив
  # 4. Останавливается когда:
  #    - закончились страницы (page >= total_pages)
  #    - достигнут лимит max_pages
  #
  # @return [Array<Hash>] массив хешей с данными вакансий
  def fetch_for_query
    vacancies = []
    page = 0

    loop do
      # Получаем страницу с данными
      data = fetch_page_raw(page)
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

  private

  # fetch_page_raw — низкоуровневый метод для получения одной страницы
  #
  # Параметры запроса:
  # - text: поисковый запрос (например, "Ruby")
  # - per_page: количество вакансий на странице
  # - page: номер страницы (0-based)
  # - order_by: сортировка по времени публикации (сначала новые)
  #
  # @param page [Integer] номер страницы
  # @return [Hash] распарсенный JSON ответ от API
  def fetch_page_raw(page)
    params = {
      text: @query,
      per_page: @per_page,
      page: page,
      order_by: 'publication_time'
    }

    # GET-запрос к /vacancies с параметрами
    response = connection.get('/vacancies', params)

    # Обработка ошибок API
    unless response.success?
      Rails.logger.error("HH error: #{response.status} #{response.body}")
      return { "items" => [], "pages" => 0 }
    end

    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |conn|
      conn.headers['HH-User-Agent'] = 'your-app-name/1.0 (kuzmenkov.vova2@gmail)'
      conn.headers['Accept'] = 'application/json'
    end
  end
end
