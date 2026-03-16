# Сервис, который рассылает вакансии подписчикам в Telegram
class TelegramNotifier
  def initialize(language:)
    @language = language
    @bot = Telegram::Bot::Client.new(TELEGRAM_BOT_TOKEN)
  end

  def send_vacancies(vacancies)
    subscribers = Subscription.where(language: @language, active: true)
    return if subscribers.empty?

    message = build_message(vacancies)

    subscribers.each do |subscriber|
      send_message(subscriber, message)
    end
  end

  private

  def send_message(subscriber, message)
    @bot.api.send_message(
      chat_id: subscriber.telegram_id,
      text: message,
      parse_mode: "Markdown"
    )
  rescue => e
    Rails.logger.error("Не удалось отправить сообщение.\n Ошибка #{e.message}")
  end

  def build_message(vacancies)
    count = vacancies.count
    text = "🔔 Новые вакансии (#{count})"

    vacancies.first(5).each_with_index do |vacancy, index|
      text += "#{index+1}.#{vacancy.name}\n"
      text += "Зарплата: #{vacancy.salary_from}\n"
      text += "Компания: #{vacancy.employer}\n"
      text += "Локация: #{vacancy.area}\n"
      # text += "Ссылка на вакансию: #{vacancy.url}\n"
    end

    if count > 5
      text += "Еще #{count - 5} вакансий"
    end
    text
  end
end
