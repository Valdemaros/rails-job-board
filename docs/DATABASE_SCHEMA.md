# 📊 Схема базы данных

**Проект:** HH Parser — Telegram бот для вакансий  
**База данных:** PostgreSQL  
**Обновлено:** Март 2026

---

## 📁 Таблица: `vacancies`

Вакансии с HH.ru

| Колонка | Тип | Nullable | Default | Описание |
|---------|-----|----------|---------|----------|
| `id` | bigint | ❌ NO | auto | Первичный ключ |
| `hh_id` | string | ❌ NO | — | Уникальный ID вакансии на HH.ru |
| `name` | string | ❌ NO | — | Название вакансии (например, "Ruby Developer") |
| `area` | string | ✅ YES | NULL | Город (например, "Москва", "Минск") |
| `employer` | string | ✅ YES | NULL | Название компании |
| `experience` | string | ✅ YES | NULL | Требуемый опыт (например, "От 1 года до 3 лет") |
| `salary_from` | integer | ✅ YES | NULL | Зарплата от |
| `salary_to` | integer | ✅ YES | NULL | Зарплата до |
| `url` | string | ✅ YES | NULL | Ссылка на вакансию на HH.ru |
| `published_at` | datetime | ✅ YES | NULL | Дата публикации на HH.ru |
| `snippet` | text | ✅ YES | NULL | Описание/требования (HTML) |
| `created_at` | datetime | ❌ NO | — | Когда добавлено в БД |
| `updated_at` | datetime | ❌ NO | — | Когда обновлено в БД |

### Индексы:
```sql
CREATE UNIQUE INDEX index_vacancies_on_hh_id ON vacancies(hh_id);
```

### Пример данных:
```
id | hh_id     | name            | area   | employer  | salary_from | created_at
---|-----------|-----------------|--------|-----------|-------------|------------
1  | 123456789 | Ruby Developer  | Москва | ООО Рога  | 150000      | 2026-03-01
2  | 987654321 | Python Dev      | Минск  | ЗАО Копыта| 200000      | 2026-03-02
```

---

## 📁 Таблица: `subscriptions`

Подписки пользователей Telegram

| Колонка | Тип | Nullable | Default | Описание |
|---------|-----|----------|---------|----------|
| `id` | bigint | ❌ NO | auto | Первичный ключ |
| `telegram_id` | bigint | ❌ NO | — | Уникальный ID пользователя Telegram |
| `username` | string | ✅ YES | NULL | Username пользователя (например, "@vladimir") |
| `language` | string | ❌ NO | — | Язык программирования (ruby, python, java...) |
| `active` | boolean | ✅ YES | true | Активна ли подписка |
| `created_at` | datetime | ❌ NO | — | Когда подписался |
| `updated_at` | datetime | ❌ NO | — | Когда обновил подписку |

### Индексы:
```sql
CREATE UNIQUE INDEX index_subscriptions_on_telegram_id ON subscriptions(telegram_id);
CREATE INDEX index_subscriptions_on_active ON subscriptions(active);
CREATE INDEX index_subscriptions_on_language ON subscriptions(language);
```

### Пример данных:
```
id | telegram_id  | username    | language | active | created_at
---|--------------|-------------|----------|--------|------------
1  | 123456789    | @vladimir   | ruby     | true   | 2026-03-01
2  | 987654321    | @alexey     | python   | true   | 2026-03-02
3  | 555666777    | @dmitry     | java     | false  | 2026-02-28
```

---

## 🔗 Связи между таблицами

```
┌─────────────────────────────────────────────────────────┐
│  subscriptions                                          │
│  └── telegram_id (уникальный ID пользователя)          │
│  └── language (на какой язык подписан)                 │
└─────────────────────────────────────────────────────────┘
                          │
                          │ (нет прямой связи)
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  vacancies                                              │
│  └── hh_id (уникальный ID вакансии)                    │
│  └── language (неявно, по названию/описанию)           │
└─────────────────────────────────────────────────────────┘
```

**Связь логическая (не через foreign key):**
- `subscriptions.language` → фильтрует `vacancies` по названию/описанию
- `subscriptions.telegram_id` → используется для отправки уведомлений

---

## 📈 ER-диаграмма

```
┌──────────────────────┐         ┌──────────────────────┐
│   subscriptions      │         │      vacancies       │
├──────────────────────┤         ├──────────────────────┤
│ id (PK)              │         │ id (PK)              │
│ telegram_id (UNIQUE) │         │ hh_id (UNIQUE)       │
│ username             │         │ name                 │
│ language             │────────┼│ area                 │
│ active               │         │ employer             │
│ created_at           │         │ experience           │
│ updated_at           │         │ salary_from          │
└──────────────────────┘         │ salary_to            │
                                 │ url                  │
                                 │ published_at         │
                                 │ snippet              │
                                 │ created_at           │
                                 │ updated_at           │
                                 └──────────────────────┘
```

---

## 🔍 Типовые запросы

### Найти все активные подписки:
```sql
SELECT * FROM subscriptions WHERE active = true;
```

### Найти подписки по языку:
```sql
SELECT telegram_id, username FROM subscriptions 
WHERE language = 'ruby' AND active = true;
```

### Найти вакансии за последние 2 недели:
```sql
SELECT * FROM vacancies 
WHERE published_at >= NOW() - INTERVAL '14 days'
ORDER BY published_at DESC;
```

### Найти новые вакансии для подписчиков Ruby:
```sql
SELECT v.*, s.telegram_id
FROM vacancies v
CROSS JOIN subscriptions s
WHERE s.language = 'ruby' 
  AND s.active = true
  AND v.created_at > NOW() - INTERVAL '5 minutes'
  AND v.name ILIKE '%ruby%';
```

---

## 📊 Статистика (примерная)

| Таблица | Ожидаемое количество | Рост в день |
|---------|---------------------|-------------|
| `vacancies` | 500-1000 | +50-100 |
| `subscriptions` | 10-100 | +1-10 |

---

## 🚀 Планы на будущее

### Возможные новые таблицы:

#### `sent_notifications` (история отправок)
| Колонка | Тип | Описание |
|---------|-----|----------|
| `id` | bigint | Первичный ключ |
| `subscription_id` | bigint | Ссылка на подписку |
| `vacancy_id` | bigint | Ссылка на вакансию |
| `sent_at` | datetime | Когда отправлено |

**Зачем:** Чтобы не отправлять одну и ту же вакансию дважды

---

#### `users` (пользователи Telegram)
| Колонка | Тип | Описание |
|---------|-----|----------|
| `id` | bigint | Первичный ключ |
| `telegram_id` | bigint | ID в Telegram |
| `username` | string | Username |
| `first_name` | string | Имя |
| `last_name` | string | Фамилия |
| `created_at` | datetime | Когда начал пользоваться |

**Зачем:** Хранить информацию о пользователях отдельно от подписок

---

#### `vacancy_languages` (связь вакансий и языков)
| Колонка | Тип | Описание |
|---------|-----|----------|
| `vacancy_id` | bigint | Ссылка на вакансию |
| `language` | string | Язык (ruby, python...) |

**Зачем:** Чтобы не фильтровать каждый раз по названию

---

## 📝 Миграции

### Текущие миграции:

```bash
db/migrate/
├── 20260223085150_create_vacancies.rb
├── 20260223165537_create_subscriptions.rb
└── 20260302XXXXXX_add_fields_to_subscriptions.rb  ← создать
```

### Пример миграции для subscriptions:

```ruby
class AddFieldsToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :telegram_id, :bigint, null: false
    add_column :subscriptions, :username, :string
    add_column :subscriptions, :language, :string, null: false
    add_column :subscriptions, :active, :boolean, default: true
    
    add_index :subscriptions, :telegram_id, unique: true
    add_index :subscriptions, :active
    add_index :subscriptions, :language
  end
end
```

---

## 🎯 Проверка схемы

### Посмотреть текущую схему:
```bash
bin/rails db:schema:dump
cat db/schema.rb
```

### Посмотреть структуру таблицы:
```bash
bin/rails c
> Subscription.column_names
> Subscription.columns_hash
> Vacancy.column_names
```

---

**Последнее обновление:** Март 2026  
**Следующий шаг:** Создать миграцию для добавления полей в `subscriptions`
