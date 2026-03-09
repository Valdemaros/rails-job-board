# Локальная разработка

## Быстрый старт

### 1. Запустить Redis (в отдельном терминале)
```bash
redis-server
```

Или в фоне:
```bash
redis-server --daemonize yes
```

Проверить:
```bash
redis-cli ping
# Ответ: PONG
```

### 2. Запустить Rails сервер
```bash
bin/rails server
```

### 3. Запустить Sidekiq (в отдельном терминале)
```bash
bundle exec sidekiq
```

Sidekiq автоматически подхватит cron-задачу из `config/sidekiq.yml`:
- **fetch_vacancies** — каждые 5 минут (`*/5 * * * *`)
- Запускает `FetchVacanciesJob`
- Парсит HH.ru, фильтрует и импортирует вакансии

## Проверка работы

### Проверить очередь задач
```bash
redis-cli llen queue:default
```

### Запустить задачу вручную
```bash
bin/rails runner "FetchVacanciesJob.perform_async"
```

### Посмотреть вакансии в БД
```bash
bin/rails console
> Vacancy.count
> Vacancy.order(created_at: :desc).limit(5)
```

## Структура задач

```
config/sidekiq.yml
└── :schedule
    └── fetch_vacancies
        ├── cron: "*/5 * * * *"
        ├── class: "FetchVacanciesJob"
        └── queue: default

app/jobs/fetch_vacancies_job.rb
└── perform
    ├── HhScraper.new.fetch_for_query    # Парсинг HH.ru
    ├── VacancyFilter.new.call           # Фильтрация
    └── VacancyImporter.new.import       # Импорт в БД
```

## Полезные команды

```bash
# Проверить состояние миграций
bin/rails db:migrate:status

# Посмотреть вакансии
bin/rails console
> Vacancy.order(created_at: :desc).limit(5)

# Очистить базу и начать заново
bin/rails db:reset

# Очистить Redis
redis-cli FLUSHDB

# Запустить все сервисы сразу (если есть foreman)
foreman start
```

## Telegram бот

Токен уже настроен в credentials:
```bash
bin/rails credentials:show
# telegram.bot_token: 8736368536:AAHG54YQbUFEeG7trMfuLW5MjIQzTlmyHFM
```

Webhook настроен на `/telegram/webhook`

Для локального тестирования webhook используй ngrok:
```bash
ngrok http 3000
# Затем настрой webhook в Telegram:
# https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://<ngrok-url>/telegram/webhook
```

## Исправленные проблемы

### Конфликт gem'ов (Решено)
- **Проблема**: `sidekiq-scheduler 6.x` + `connection_pool 3.x` несовместимы
- **Решение**: Обновлен `sidekiq` до версии 8.x и используется `sidekiq-cron 2.x`

### Синтаксическая ошибка в HhScraper (Решено)
- **Проблема**: `"pages" >= 0` вместо `"pages" => 0`
- **Решение**: Исправлено в `app/services/hh_scraper.rb`
