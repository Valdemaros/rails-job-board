# lib/tasks/telegram.rake
namespace :telegram do
  desc "Run Telegram bot poller"
  task bot: :environment do
    TelegramBotRunner.run
  end
end

