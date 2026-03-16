# app/controllers/telegram_webhooks_controller.rb

# Контроллер для обработки webhook от Telegram бота
# Telegram шлёт POST-запросы на /telegram/webhook при каждом сообщении пользователя
class TelegramWebhooksController < ApplicationController
  # Telegram шлёт POST без CSRF-токена, поэтому отключаем стандартную защиту
  # Иначе Rails будет блокировать запросы с ошибкой "Invalid Authenticity Token"
  protect_from_forgery with: :null_session

  # ==================== ГЛАВНЫЙ МЕТОД ====================
  # Сюда приходят ВСЕ запросы от Telegram
  def callback
    # 1. Проверяем наличие токена бота
    # Если токена нет — возвращаем ошибку 400 (Bad Request)
    if TELEGRAM_BOT_TOKEN.blank?
      Rails.logger.error "Telegram token is missing"
      return head :bad_request
    end

    # 2. Создаём клиент для вызова Telegram Bot API
    # Через этот объект отправляем сообщения пользователям
    @bot = Telegram::Bot::Client.new(TELEGRAM_BOT_TOKEN)

    # 3. Извлекаем данные из запроса Telegram
    # В зависимости от типа события (сообщение или нажатие кнопки)
    @payload = extract_payload
    return head :ok if @payload.nil?

    # 4. Отправляем событие на обработку (маршрутизация)
    dispatch_event

    # 5. Возвращаем 200 OK — Telegram требует простой ответ
    # Если не вернуть 200, Telegram будет считать что webhook не работает
    head :ok
  end

  private

  # ==================== ИЗВЛЕЧЕНИЕ ДАННЫХ ====================
  # Достаёт данные из params и кладёт в удобный хэш @payload
  #
  # Telegram шлёт два типа событий:
  # 1. message — когда пользователь написал текстовое сообщение
  # 2. callback_query — когда пользователь нажал кнопку под сообщением
  def extract_payload
    if params["callback_query"]
      # Пользователь нажал кнопку — извлекаем данные callback_query
      {
        type: :callback,                          # Тип события: нажатие кнопки
        chat_id: params["callback_query"].dig("from", "id"),  # ID чата пользователя
        username: params["callback_query"].dig("from", "username"),  # Имя пользователя
        data: params["callback_query"]["data"],   # Данные кнопки (например, "subscribe_ruby")
        callback_id: params["callback_query"]["id"]  # ID callback для ответа Telegram
      }
    elsif params["message"]
      # Пользователь написал сообщение — извлекаем данные message
      {
        type: :message,                           # Тип события: текстовое сообщение
        chat_id: params["message"].dig("chat", "id"),  # ID чата пользователя
        username: params["message"].dig("from", "username"),  # Имя пользователя
        text: params["message"]["text"].to_s      # Текст сообщения (например, "/start")
      }
    end
    # Если ни то ни другое — вернётся nil
  end

  # ==================== МАРШРУТИЗАЦИЯ СОБЫТИЙ ====================
  # Отправляет событие на нужный обработчик в зависимости от типа
  def dispatch_event
    if @payload[:type] == :callback
      # Если нажали кнопку — обрабатываем callback_query
      handle_callback_event
    elsif @payload[:type] == :message
      # Если написали сообщение — обрабатываем текстовую команду
      handle_message_event
    end
  end

  # ==================== ОБРАБОТКА НАЖАТИЙ КНОПОК ====================
  # Вызывается когда пользователь нажимает кнопку под сообщением
  def handle_callback_event
    # Сначала отвечаем Telegram что получили нажатие
    # Это убирает "часы" (⏳) на кнопке — показывает что бот работает
    answer_callback

    # Смотрим что за кнопка была нажата (данные из callback_data)
    case @payload[:data]
    when "subscribe"
      # Кнопка "🔔 Подписаться" — показываем выбор языка
      show_language_buttons
    when /^subscribe_(.+)$/
      # Кнопка с языком (subscribe_ruby, subscribe_python и т.д.)
      # Регулярное выражение извлекает язык: "subscribe_ruby" → "ruby"
      language = Regexp.last_match[1].to_sym
      save_subscription_and_notify(language)
    when "unsubscribe"
      Subscription.find_by(telegram_id: @payload[:chat_id])&.destroy
        send_message("Вы отписались")
    when "status"
      # Кнопка "📊 Мой статус" — показываем текущую подписку
      show_subscription_status

    when "latest"
      # Кнопка "📬 Последние" — показать последнюю вакансию
      show_latest_vacancy

    when "help"
      # Кнопка "❓ Помощь" — показать справку
      show_help

    when "back"
      # Кнопка "◀️ Назад" — вернуться в главное меню
      send_welcome_message
    end
  end

  # ==================== ОБРАБОТКА ТЕКСТОВЫХ СООБЩЕНИЙ ====================
  # Вызывается когда пользователь пишет команду (/start или другие)
  def handle_message_event
    # Смотрим текст сообщения
    if @payload[:text] == "/start"
      # Команда /start — приветствие с кнопками
      send_welcome_message
    elsif @payload[:text].start_with?("/")
      # Если написали другую команду — напоминаем что есть только кнопки
      send_message("👆 Используйте кнопки в меню для управления ботом.")
    end
    # Все остальные сообщения (текст, фото и т.д.) — игнорируем
  end

  # ==================== CALLBACK ОБРАБОТЧИКИ ====================

  # Отвечает Telegram что получили callback (убирает "часы" на кнопке)
  def answer_callback
    # Пропускаем в тестах чтобы не было ошибок API
    return if Rails.env.test?
    @bot.api.answer_callback_query(callback_query_id: @payload[:callback_id])
  end

  # Отправляет приветственное сообщение с главными кнопками
  def send_welcome_message
    message = "👋 Привет! #{@payload[:username]}\n\n"
    message += "Я бот для поиска IT-вакансий с HH.ru\n"
    message += "📌 Что я умею:\n"
    message += "• Присылаю свежие вакансии по твоему языку\n"
    message += "• Обновляю базу каждые 5 минут\n"
    message += "• Только проверенные работодатели\n\n"
    message += "👇 Выбери действие:"

    # Inline-клавиатура: массив строк, каждая строка — массив кнопок
    keyboard = [
      [
        { text: "🔔 Подписаться", callback_data: "subscribe" },
        { text: "📊 Мой статус", callback_data: "status" }
      ],
      [
        { text: "📬 Последние", callback_data: "latest" },
        { text: "❓ Помощь", callback_data: "help" }
      ]
    ]

    send_message(message, keyboard: keyboard)
  end

  # Показывает кнопки с выбором языка программирования
  def show_language_buttons
    message = "Отлично! Давай выберем язык\n\n"
    message += "На какие вакансии хочешь подписаться?"

    # Inline-клавиатура: 3 строки по 2 кнопки + кнопка "Назад"
    keyboard = [
      [
        { text: "💎 Ruby", callback_data: "subscribe_ruby" },
        { text: "🐍 Python", callback_data: "subscribe_python" }
      ],
      [
        { text: "☕ Java", callback_data: "subscribe_java" },
        { text: "🔷 Go", callback_data: "subscribe_go" }
      ],
      [
        { text: "🌐 JavaScript", callback_data: "subscribe_javascript" },
        { text: "🐘 PHP", callback_data: "subscribe_php" }
      ],
      [
        { text: "◀️ Назад", callback_data: "back" }
      ]
    ]

    send_message(message, keyboard: keyboard)
  end

  # ==================== РАБОТА С БАЗОЙ ДАННЫХ ====================

  # Сохраняет подписку в базу данных и уведомляет пользователя
  def save_subscription_and_notify(language)
    # Ищем существующую подписку по telegram_id
    subscription = Subscription.find_by(telegram_id: @payload[:chat_id])

    if subscription
      # Если подписка уже есть — обновляем язык
      subscription.update!(language: language)
      send_message("✅ Язык изменён на #{language_name(language)}")
    else
      # Если подписки нет — создаём новую
      Subscription.create!(
        telegram_id: @payload[:chat_id],
        username: @payload[:username] || "unknown",
        language: language
      )
      send_message("✅Готово\n\n
                   Ты подписан на вакансии: #{language_name(language)}\n\n
                   Сейчас пришлю последние вакансии.")
    end

    # Отправляем последние 5 вакансий по этому языку
    send_recent_vacancies(language)
  end

  # Показывает статус подписки пользователя
  def show_subscription_status
    # Ищем подписку в базе данных
    subscription = Subscription.find_by(telegram_id: @payload[:chat_id])

    if subscription
      # Подписка есть — показываем q
      language = language_name(subscription.language)
      created_date = subscription.created_at.strftime("%d %B %Y")
      message = "📊 Твоя подписка\n\n"
      message += "Язык: #{language}\n"
      message += "Статуc: ✅ Активна\n"
      message += "Подписан: #{created_date}\n"

      keyboard = [
        [
          { text: "Сменить язык", callback_data: "subscribe" }
        ],
        [
          { text: "Отписаться", callback_data: "unsubscribe" }
        ]
      ]
    else
      # Подписки нет — предлагаем подписаться
      message = "❌ Вы не подписаны.\n\nНажмите 🔔 Подписаться."
      keyboard = nil
    end

    send_message(message, keyboard: keyboard)
  end

  # ==================== ДРУГИЕ КОМАНДЫ ====================

  # Показывает последнюю вакансию из базы
  def show_latest_vacancy
    # Берём самую свежую вакансию (по дате создания)
    vacancy = Vacancy.order(created_at: :desc).first

    if vacancy
      # Формируем сообщение с деталями вакансии
      message = "#{vacancy.name}\n#{vacancy.area} · #{vacancy.employer}\n#{vacancy.url}"
    else
      # В базе пока нет вакансий
      message = "Пока нет вакансий."
    end

    send_message(message)
  end

  # Показывает справку по боту
  def show_help
    message = "❓ Помощь\n\n"
    message += "🔔 Подписаться — выбрать язык для вакансий\n"
    message += "📊 Мой статус — проверить подписку\n"
    message += "📬 Последние — последняя вакансия\n\n"
    message += "Используйте кнопки для управления."

    send_message(message)
  end

  # ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  # Отправляет последние 5 вакансий по языку
  def send_recent_vacancies(language)
    vacancies = Vacancy.where("name ILIKE ?", "%#{language}%").order(created_at: :desc).limit(5)

    if vacancies.any?
      # Формируем сообщение
      message = build_vacancies_message(vacancies, language)
      send_message(message)
    else
      send_message("📭 Пока нет вакансий по языку #{language_name(language)}.\n\nЗаходи позже!")
    end
  rescue => e
    Rails.logger.error("Ошибка отправки вакансий: #{e.message}")
  end

  # Формирует текст сообщения с вакансиями
  def build_vacancies_message(vacancies, language)
    count = vacancies.count
    text = "🔔 Вакансии #{language_name(language)} (#{count})\n\n"

    vacancies.each_with_index do |vacancy, index|
      text += "#{index + 1}. #{vacancy.name}\n"
      text += "   💰 #{format_salary(vacancy)}\n"
      text += "   🏢 #{vacancy.employer || 'Не указано'} · #{vacancy.area || 'Не указано'}\n"
      text += "   🔗 [Открыть](#{vacancy.url})\n\n"
    end

    text
  end

  # Форматирует зарплату
  def format_salary(vacancy)
    from = vacancy.salary_from
    to = vacancy.salary_to

    if from && to
      "от #{from} до #{to} руб."
    elsif from
      "от #{from} руб."
    elsif to
      "до #{to} руб."
    else
      "ЗП не указана"
    end
  end

  # Отправляет сообщение пользователю
  #
  # Параметры:
  # - text: текст сообщения
  # - keyboard: (опционально) inline-клавиатура с кнопками
  def send_message(text, keyboard: nil)
    # Пропускаем в тестах чтобы не было ошибок API
    return if Rails.env.test?

    options = { chat_id: @payload[:chat_id], text: text }

    # Если передана клавиатура — добавляем её в сообщение
    if keyboard
      options[:reply_markup] = { inline_keyboard: keyboard }.to_json
    end

    Rails.logger.info ">>> Sending message to chat_id=#{@payload[:chat_id]}"

    @bot.api.send_message(**options)

    Rails.logger.info ">>> Message sent successfully"
  rescue => e
    Rails.logger.error ">>> Failed to send message: #{e.class} - #{e.message}"
    raise e
  end

  # Переводит название языка в читаемый вид
  # Например: "ruby" → "Ruby", "python" → "Python"
  def language_name(language_symbol)
    {
      ruby: "Ruby",
      python: "Python",
      java: "Java",
      go: "Go",
      javascript: "JavaScript",
      php: "PHP"
    }[language_symbol.to_sym] || language_symbol.to_s
  end
end
