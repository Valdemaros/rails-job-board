require "telegram/bot"

class TelegramBotRunner
  def self.run
    token = Rails.application.credentials.dig(:telegram, :bot_token)

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        case message.text
        when "/start"
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Привет! Я бот для Ruby-вакансий."
          )
        when "/latest"
          vacancy = Vacancy.order(created_at: :desc).first

        when "/update"
          # вызов фоновой джобы через sidekiq которая забирает с hh вакансии и складывает в БД
          HhFetchJob.perform_async

          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Обновляю вакансии, проверь /latest через минуту."
          )
          text =
            if vacancy
              "#{vacancy.name}\n#{vacancy.area} · #{vacancy.employer}\n#{vacancy.url}"
            else
              "Пока нет вакансий."
            end

          bot.api.send_message(chat_id: message.chat.id, text: text)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Команды: /start, /latest")
        end
      end
    end
  end
end
 
