class VacancyImporter
  def import(raw_vacancies)
    new_vacancies = []
    raw_vacancies.each do |data|
      next if Vacancy.exists?(hh_id: data['id'])
      vacancy = Vacancy.create!(
        hh_id: data['id'],
        name: data['name'],
        area: data.dig('area', 'name'),
        employer: data.dig('employer', 'name'),
        experience: data.dig('experience', 'name'),
        url: data['alternate_url'],
        salary_from: data.dig('salary', 'from'),
        salary_to: data.dig('salary', 'to'),
        currency: data.dig('salary', 'currency'),
        published_at: data['published_at'],
        snippet: data.dig('snippet', 'requirement')
      )
      new_vacancies << vacancy
    end
    new_vacancies
  end
end
