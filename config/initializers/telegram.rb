require "telegram/bot"

TELEGRAM_BOT_TOKEN = Rails.application.credentials.dig(:telegram, :bot_token)

if TELEGRAM_BOT_TOKEN.blank?
  Rails.logger.warn "Telegram bot token is not set in credentials"
end

