require "test_helper"

class TelegramNotifierTest < ActiveSupport::TestCase
  # setup выполняется перед каждым тестом
  setup do
    # Создаём моки для Telegram API (чтобы не отправлять реальные сообщения)
    @api_mock = mock
    @bot_mock = mock

    # @bot_mock.api возвращает @api_mock
    @bot_mock.stubs(:api).returns(@api_mock)

    # ВАЖНО: Подменяем Telegram::Bot::Client.new на наш мок
    # Без этой строки TelegramNotifier создаст реальный клиент
    Telegram::Bot::Client.stubs(:new).returns(@bot_mock)
  end

  test "sends vacancies to active subcribes" do
    # 1. Создаём тестового подписчика
    subscription = Subscription.create!(
      telegram_id: 7788,
      username: "test_user",
      language: :ruby,
      active: true
    )

    # 2. Создаём тестовую вакансию
    vacancy = Vacancy.create!(
      hh_id: "test_1",
      name: "Ruby Developer",
      employer: "Рога и копыта",
      area: "Minsk",
      salary_from: 250000,
      url: "https://hh.ru/vacancy/1"
    )

    # 3. Уточняем ожидание: send_message должен быть вызван с конкретными параметрами
    @api_mock.expects(:send_message).once.with(
      chat_id: subscription.telegram_id,  # ID подписчика
      text: anything,                      # Текст сообщения (любой)
      parse_mode: "Markdown"               # Форматирование
    )

    # 4. Вызываем метод который тестируем
    TelegramNotifier.new(language: :ruby).send_vacancies([ vacancy ])
  end

  test "build_message returns formatted text" do
    # Создаём вакансию (не сохраняем в БД, только для теста)
    vacancy = Vacancy.new(
      hh_id: "test_1",
      name: "Ruby Developer",
      employer: "Рога и копыта",
      area: "Minsk",
      salary_from: 250000,
      url: "https://hh.ru/vacancy/1"
    )

    # Создаём notifier
    notifier = TelegramNotifier.new(language: :ruby)

    # Вызываем приватный метод build_message через .send
    message = notifier.send(:build_message, [ vacancy ])

    # Проверяем что сообщение содержит ожидаемые части
    assert_match /🔔 Новые вакансии \(1\)/, message
    assert_match /1\.Ruby Developer/, message
    assert_match /Зарплата: 250000/, message
    assert_match /Компания: Рога и копыта/, message
    assert_match /Локация: Minsk/, message
  end
end
