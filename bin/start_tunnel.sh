#!/bin/bash

echo "========================================"
echo "   Запуск Telegram бота"
echo "========================================"
echo ""

# Получаем токен из credentials
BOT_TOKEN=$(bin/rails runner "puts Rails.application.credentials.dig(:telegram, :bot_token)" 2>/dev/null)

if [ -z "$BOT_TOKEN" ]; then
  echo "   ❌ Токен не найден в credentials!"
  echo "   Проверь: bin/rails credentials:edit"
  exit 1
fi

echo "   ✅ Токен загружен из credentials"

# Проверка Rails
echo "1. Проверка Rails..."
if curl -s http://localhost:3000/up | grep -q "green"; then
  echo "   ✅ Rails работает"
else
  echo "   ❌ Rails не работает!"
  echo "   Запусти: bin/rails server"
  exit 1
fi

# Остановка старого cloudflared
echo ""
echo "2. Остановка старого cloudflared..."
pkill -f "cloudflared" 2>/dev/null
sleep 2
echo "   ✅ Остановлен"

# Получение URL (запускаем cloudflared и ловим URL из логов)
echo ""
echo "3. Получение cloudflared URL..."

# Запускаем cloudflared и сохраняем логи во временный файл
cloudflared tunnel --url http://localhost:3000 > /tmp/cloudflared_startup.log 2>&1 &
CLOUDFLARED_PID=$!

# Ждём пока cloudflared выдаст URL (максимум 30 секунд)
for i in {1..30}; do
  if [ -f /tmp/cloudflared_startup.log ]; then
    URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_startup.log | tail -1)
    if [ -n "$URL" ]; then
      break
    fi
  fi
  sleep 1
done

# Проверяем что URL получен
if [ -z "$URL" ]; then
  echo "   ❌ Не удалось получить URL за 30 секунд"
  echo "   Логи cloudflared:"
  cat /tmp/cloudflared_startup.log
  exit 1
fi

echo "   ✅ URL: $URL"

# Проверяем что cloudflared всё ещё работает
if ! kill -0 $CLOUDFLARED_PID 2>/dev/null; then
  echo "   ❌ Cloudflared упал"
  echo "   Логи:"
  cat /tmp/cloudflared_startup.log
  exit 1
fi

# Сохраняем PID для будущего использования
echo $CLOUDFLARED_PID > /tmp/cloudflared.pid

# Небольшая пауза чтобы tunnel точно поднялся
sleep 2

# Обновление webhook
echo ""
echo "4. Обновление webhook в Telegram..."
WEBHOOK_URL="$URL/telegram/webhook"
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=$WEBHOOK_URL")

if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "   ✅ Webhook обновлён"
else
  echo "   ❌ Ошибка обновления webhook"
  echo "   Ответ: $RESPONSE"
  exit 1
fi

# Проверка webhook
echo ""
echo "5. Проверка webhook..."
sleep 2
WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo")
ERROR_MSG=$(echo "$WEBHOOK_INFO" | jq -r '.result.last_error_message // ""')
PENDING_COUNT=$(echo "$WEBHOOK_INFO" | jq -r '.result.pending_update_count // 0')

if [ "$ERROR_MSG" == "" ] || [ "$ERROR_MSG" == "null" ]; then
  echo "   ✅ Webhook работает"
else
  echo "   ⚠️  Есть ошибка: $ERROR_MSG"
  if [ "$PENDING_COUNT" -gt 0 ]; then
    echo "   В очереди $PENDING_COUNT запросов"
  fi
  echo "   (может быть кэш Telegram, подожди 1-2 минуты)"
fi

# Сохраняем текущий URL
echo "$WEBHOOK_URL" > /tmp/cloudflared_url.txt

echo ""
echo "========================================"
echo "   ✅ ГОТОВО!"
echo "========================================"
echo ""
echo "Webhook URL: $WEBHOOK_URL"
echo "Cloudflared PID: $CLOUDFLARED_PID"
echo ""
echo "Напиши боту /start в Telegram"
echo ""
echo "Для остановки:"
echo "  pkill -f cloudflared"
echo "  или"
echo "  kill $CLOUDFLARED_PID"
echo ""
echo "Логи cloudflared: /tmp/cloudflared_startup.log"
echo ""
