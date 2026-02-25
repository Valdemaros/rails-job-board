class HhScraper
  BASE_URL = 'https://api.hh.ru'

  def initialize(query: 'Ruby', areas: [113, 16], per_page: 100)
    @query = query
    @areas = areas
    @per_page = per_page
  end

  def fetch_vacancies
    @areas.flat_map { |area| fetch_for_area(area) }
  end

  private

  def fetch_for_area(area)
    params = { text: @query, area: area, per_page: @per_page, order_by: 'publication_time' }
    response = connection.get('/vacancies', params)
    data = JSON.parse(response.body)
    binding.pry
    data['items'] || []
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |conn|
      conn.headers['User-Agent'] = 'HH-Parser/1.0'
      conn.headers['Accept'] = 'application/json'
    end
  end
end
