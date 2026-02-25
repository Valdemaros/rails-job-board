class VacancyFilter

  KEYWORDS = %w[ruby rails elixir].freeze
  LOCATIONS = %w[113 16].freeze

  # INCOME 
  def initialize(data)
    @vacancies = data['name']
    @locations = data.dig("area", "id")
  end

  def call
    @vacancies.select { |v| keyword_match?(v) } && @locations.select { |loc| location_match?(loc) }
  end

  private

  # True has to be in select block

  def keyword_match?(vacancy)
    name = vacancy['name'].to_s.downcase
    KEYWORDS.any? { |keyword| name.include?(keyword) }
  end

  def location_match?(location)
    area = location.dig("area", "id")
    LOCATIONS.any? { |loc| location.include?(loc) }
  end
end


# API DEEP SEEK
# sk-61a06e207bfd4e4c9b0f7f1505948e03



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

