class VacancyFilter
  KEYWORDS = %w[
    ruby
    rails
    elixir
    ruby on rails
    программист

  ].freeze

  def initialize(vacancies)
    @vacancies = vacancies
  end

  def call
    @vacancies.select { |vacancy| relevant?(vacancy) }
  end

  private

  def relevant?(vacancy)
    keyword_match?(vacancy) 
    # && location_match?(vacancy)
  end

  def keyword_match?(vacancy)
    text = [
      vacancy["name"],
      vacancy.dig("snippet", "requirement"),
      vacancy.dig("snippet", "responsibility")
    ].compact.join(" ").downcase

    KEYWORDS.any? { |keyword| text.include?(keyword) }
  end

  # def location_match?(vacancy)
  #   area_id = vacancy.dig("area", "id").to_s
  #   LOCATIONS.include? (area_id) 
  # end
end



# class VacancyFilter
#   KEYWORDS = %w[ruby rails].freeze
#
#   def initialize(vacancies)
#     @vacancies = vacancies
#   end
#
#   def call
#     @vacancies.select { |v| relevant?(v) }
#   end
#
#   private
#
#   def relevant?(vacancy)
#     name = vacancy['name'].to_s.downcase
#     KEYWORDS.any? { |keyword| name.include?(keyword) }
#   end
# end

