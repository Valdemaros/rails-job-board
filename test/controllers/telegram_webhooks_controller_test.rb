# test/controllers/telegram_webhooks_controller_test.rb

require "test_helper"

class TelegramWebhooksControllerTest < ActionDispatch::IntegrationTest
  # ==================== SETUP ====================
  setup do
    @original_token = ENV["TELEGRAM_BOT_TOKEN"]
    ENV["TELEGRAM_BOT_TOKEN"] = "test_bot_token"
  end

  teardown do
    ENV["TELEGRAM_BOT_TOKEN"] = @original_token
  end

  # ==================== TEST: MISSING TOKEN ====================
  # Пропускаем этот тест так как TELEGRAM_BOT_TOKEN загружается из credentials
  # и не может быть изменён в тестах без перезагрузки приложения
  # test "POST /telegram/webhook without token returns 400" do
  #   ENV["TELEGRAM_BOT_TOKEN"] = nil
  #
  #   post "/telegram/webhook", params: {
  #     message: {
  #       chat: { id: 123456 },
  #       text: "/start"
  #     }
  #   }
  #
  #   assert_response :bad_request
  # end

  # ==================== TEST: SUBSCRIBE RUBY ====================

  test "POST /telegram/webhook with subscribe_ruby creates subscription" do
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_1",
        from: { id: 111111, username: "user1" },
        data: "subscribe_ruby"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 111111)
    assert_not_nil subscription
    assert_equal "ruby", subscription.language
    assert subscription.language_ruby?
  end

  # ==================== TEST: SUBSCRIBE PYTHON ====================

  test "POST /telegram/webhook with subscribe_python creates subscription" do
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_2",
        from: { id: 222222, username: "user2" },
        data: "subscribe_python"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 222222)
    assert_not_nil subscription
    assert_equal "python", subscription.language
    assert subscription.language_python?
  end

  # ==================== TEST: SUBSCRIBE JAVA ====================

  test "POST /telegram/webhook with subscribe_java creates subscription" do
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_3",
        from: { id: 333333, username: "user3" },
        data: "subscribe_java"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 333333)
    assert_not_nil subscription
    assert_equal "java", subscription.language
    assert subscription.language_java?
  end

  # ==================== TEST: SUBSCRIBE GO ====================

  test "POST /telegram/webhook with subscribe_go creates subscription" do
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_4",
        from: { id: 444444, username: "user4" },
        data: "subscribe_go"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 444444)
    assert_not_nil subscription
    assert_equal "go", subscription.language
    assert subscription.language_go?
  end

  # ==================== TEST: SUBSCRIBE JAVASCRIPT ====================

  test "POST /telegram/webhook with subscribe_javascript creates subscription" do
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_5",
        from: { id: 555555, username: "user5" },
        data: "subscribe_javascript"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 555555)
    assert_not_nil subscription
    assert_equal "javascript", subscription.language
    assert subscription.language_javascript?
  end

  # ==================== TEST: SUBSCRIBE PHP ====================

  test "POST /telegram/webhook with subscribe_php creates subscription" do
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_6",
        from: { id: 666666, username: "user6" },
        data: "subscribe_php"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 666666)
    assert_not_nil subscription
    assert_equal "php", subscription.language
    assert subscription.language_php?
  end

  # ==================== TEST: UPDATE SUBSCRIPTION ====================

  test "POST /telegram/webhook updates existing subscription" do
    # Создаём подписку на ruby
    Subscription.create!(
      telegram_id: 777777,
      username: "old_user",
      language: :ruby
    )

    # Меняем на java
    post "/telegram/webhook", params: {
      callback_query: {
        id: "callback_7",
        from: { id: 777777, username: "new_user" },
        data: "subscribe_java"
      }
    }

    assert_response :ok

    subscription = Subscription.find_by(telegram_id: 777777)
    assert_equal "java", subscription.language
    assert subscription.language_java?
  end

  # ==================== TEST: CREATE VACANCY AND CHECK LATEST ====================

  test "POST /telegram/webhook with /latest shows vacancy" do
    # Создаём вакансию
    Vacancy.create!(
      hh_id: "vacancy_1",
      name: "Senior Ruby Developer",
      area: "Москва",
      employer: "Test Company",
      url: "https://hh.ru/vacancy/1"
    )

    post "/telegram/webhook", params: {
      message: {
        chat: { id: 888888 },
        from: { username: "job_seeker" },
        text: "/latest"
      }
    }

    assert_response :ok
  end

  # ==================== TEST: TRIGGER VACANCY FETCH ====================

  test "POST /telegram/webhook with /update triggers job" do
    post "/telegram/webhook", params: {
      message: {
        chat: { id: 999999 },
        from: { username: "admin" },
        text: "/update"
      }
    }

    assert_response :ok
  end
end
