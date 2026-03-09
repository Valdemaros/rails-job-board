# 🚀 Как запустить Telegram бота

## 📋 Быстрый старт

---

## ⚠️ Важно перед запуском

1. **Rails должен быть запущен** на `http://localhost:3000`
2. **Cloudflared иногда не подключается с первого раза** — если таймаут, запусти ещё раз
3. **URL меняется каждый раз** — нужно копировать новый и обновлять webhook

---

## 🔧 Шаг 1: Проверь что Rails работает

```bash
curl http://localhost:3000/up
```

**Должно вернуть:**

```html
<!DOCTYPE html><html><body style="background-color: green"></body></html>
```

**Если нет — запусти Rails:**

```bash
bin/rails server
```

---

## 🔧 Шаг 2: Запусти cloudflared и получи URL

```bash
timeout 20 cloudflared tunnel --url http://localhost:3000 2>&1 | grep -o 'https://[^[:space:]]*trycloudflare.com' | head -1
```

**Скопируй URL который появится!**

**Пример вывода:**

```
https://increase-evaluation-landscapes-hook.trycloudflare.com
```

**Если пусто или ошибка — запусти ещё раз** (Cloudflare API иногда не отвечает).

---

## 🔧 Шаг 3: Запусти cloudflared в фоне

```bash
cloudflared tunnel --url http://localhost:3000 &
```

**`&` означает:** запуск в фоне (терминал не блокируется, можно закрывать).

---

## 🔧 Шаг 4: Обнови webhook

**Вставь свой URL из Шага 2:**

```bash
curl -X POST "https://api.telegram.org/bot8736368536:AAHG54YQbUFEeG7trMfuLW5MjIQzTlmyHFM/setWebhook?url=ТВОЙ_URL/telegram/webhook"
```

**Пример:**

```bash
curl -X POST "https://api.telegram.org/bot8736368536:AAHG54YQbUFEeG7trMfuLW5MjIQzTlmyHFM/setWebhook?url=https://increase-evaluation-landscapes-hook.trycloudflare.com/telegram/webhook"
```

**Должно вернуть:**

```json
{"ok":true,"result":true,"description":"Webhook was set"}
```

---

## 🔧 Шаг 5: Проверь что работает

```bash
curl -s "https://api.telegram.org/bot8736368536:AAHG54YQbUFEeG7trMfuLW5MjIQzTlmyHFM/getWebhookInfo" | jq '.result'
```

**Успех:**

```json
{
  "url": "https://...trycloudflare.com/telegram/webhook",
  "pending_update_count": 0,
  "last_error_message": ""
}
```

---

## 🔧 Шаг 6: Напиши боту в Telegram

1. Открой Telegram
2. Найди бота (@hhshotbot)
3. Напиши `/start`
4. Должно прийти сообщение с кнопками ✅

---

## 🛑 Как остановить

### Cloudflared (в фоне)

```bash
pkill cloudflared
```

### Rails сервер

```bash
pkill -f "rails server"
```

---

## 🚀 Автоматический скрипт (рекомендую!)

**Вместо ручных команд используй скрипт:**

### Создать скрипт:

```bash
cat > bin/start_tunnel.sh << 'EOF'
#!/bin/bash

echo "=== Запуск Telegram бота ==="
echo ""

# Проверка Rails
echo "1. Проверка Rails..."
if curl -s http://localhost:3000/up | grep -q "green"; then
  echo "   ✅ Rails работает"
else
  echo "   ❌ Rails не работает! Запусти: bin/rails server"
  exit 1
fi

# Получение URL
echo "2. Получение cloudflared URL..."
URL=$(timeout 20 cloudflared tunnel --url http://localhost:3000 2>&1 | grep -o 'https://[^[:space:]]*trycloudflare.com' | head -1)

if [ -z "$URL" ]; then
  echo "   ❌ Не удалось получить URL. Попробуй ещё раз."
  exit 1
fi

echo "   ✅ URL: $URL"

# Запуск в фоне
echo "3. Запуск cloudflared в фоне..."
cloudflared tunnel --url http://localhost:3000 &
sleep 2

# Обновление webhook
echo "4. Обновление webhook..."
curl -s -X POST "https://api.telegram.org/bot8736368536:AAHG54YQbUFEeG7trMfuLW5MjIQzTlmyHFM/setWebhook?url=$URL/telegram/webhook"

echo ""
echo "=== ✅ Готово! ==="
echo "Напиши боту /start в Telegram"
EOF

chmod +x bin/start_tunnel.sh
```

### Запустить скрипт:

```bash
bin/start_tunnel.sh
```

---

## 🐛 Частые проблемы

### Бот не отвечает

1. **Проверь Rails:** `curl http://localhost:3000/up`
2. **Проверь cloudflared:** `pgrep -a cloudflared`
3. **Проверь webhook:** `getWebhookInfo` (см. Шаг 5)
4. **Смотри логи:** `tail -f log/development.log`

### Таймаут при получении URL

**Проблема:** Cloudflare API не отвечает

**Решение:** Запусти команду ещё раз (обычно со 2-3 попытки работает)

### Ошибка 530

**Проблема:** Cloudflared остановился

**Решение:** Перезапустить cloudflared и обновить webhook

### Ошибка "chat not found"

**Проблема:** Бот пытается отправить сообщение в несуществующий чат

**Решение:** Напиши боту первым, начни диалог

---

## 📝 Команды бота

| Команда | Описание |
|---------|----------|
| `/start` | Приветствие с кнопками |
| `/subscribe` | Подписаться на вакансии |
| `/status` | Показать подписку |
| `/latest` | Последняя вакансия |
| `/update` | Запустить парсинг |
| `/unsubscribe` | Отписаться |
| `/help` | Справка |

---

## 📊 Проверка работы

### Посмотреть логи

```bash
tail -f log/development.log
```

### Проверить webhook

```bash
curl -s "https://api.telegram.org/bot8736368536:AAHG54YQbUFEeG7trMfuLW5MjIQzTlmyHFM/getWebhookInfo" | jq '.result'
```

### Проверить cloudflared

```bash
pgrep -a cloudflared
```

---

**Последнее обновление:** Март 2026
