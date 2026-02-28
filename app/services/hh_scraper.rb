class HhScraper
  BASE_URL = 'https://api.hh.ru'

  def initialize(query: "Ruby", per_page: 100, max_pages: 5)
    @query = query
    @per_page = per_page
    @max_pages = max_pages
  end

  def fetch_for_query
    vacancies = []
    page = 0
    
    loop do
      data = fetch_page_raw(page)
      items = data["items"] || []
      vacancies.concat(items)

      page += 1
      total_pages = data["pages"].to_i

      break if page >= total_pages
      break if page >= @max_pages
    end

    vacancies
  end

  private
 
  def fetch_page_raw(page)
    params = {
      text: @query,
      per_page: @per_page,
      page: page,
      order_by: 'publication_time' 
    }
  
    response = connection.get('/vacancies', params)

    unless response.success?
      Rails.logger.error("HH error: #{response.status} #{response.body}")
      return { "items" => [], "pages" >= 0 }
    end
     e
    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |conn|
      conn.headers['HH-User-Agent'] = 'your-app-name/1.0 (kuzmenkov.vova2@gmail.)'
      conn.headers['Accept'] = 'application/json'
    end
  end
# структура которой задана миграциями и отражена в db/schema.rb.
end
