require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  # ============================== VALIDATION TESTS ==============================

  test "valid subscription" do
    subscription = Subscription.new(
      telegram_id: 241142352,
      username: "Balumba",
      language: :ruby
    )
    assert subscription.valid?
  end

  test "invalid without telegram_id" do
    subscription = Subscription.new(
      telegram_id: nil,
      username: "Balumba",
      language: :ruby
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:telegram_id], "can't be blank"
  end

  test "invalid without username" do
    subscription = Subscription.new(
      telegram_id: 24534445,
      username: nil,
      language: :ruby
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:username], "can't be blank"
  end

  test "invalid without language" do
    subscription = Subscription.new(
      telegram_id: 44536478,
      username: "Balumba",
      language: nil
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:language], "can't be blank"
  end

  test "telegram_id must be unique" do
    # Сначала создаём подписку
    Subscription.create!(
      telegram_id: 23121231,
      username: "Balumba",
      language: :ruby
    )

    # Пытаемся создать дубликат
    duplicate = Subscription.new(
      telegram_id: 23121231,
      username: "Petr",
      language: :python
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:telegram_id], "has already been taken"
  end

  # ============================== ENUM TESTS ==============================

  test "language enum works for ruby" do
    subscription = Subscription.new(
      telegram_id: 44536478,
      username: "Balumba",
      language: :ruby
    )
    assert subscription.valid?
    assert subscription.language_ruby?
    assert_not subscription.language_python?
  end

  test "language enum works for python" do
    subscription = Subscription.new(
      telegram_id: 55555555,
      username: "Anna",
      language: :python
    )
    assert subscription.valid?
    assert subscription.language_python?
    assert_not subscription.language_ruby?
  end

  test "language enum works for java" do
    subscription = Subscription.new(
      telegram_id: 66666666,
      username: "John",
      language: :java
    )
    assert subscription.valid?
    assert subscription.language_java?
  end

  test "language enum works for go" do
    subscription = Subscription.new(
      telegram_id: 77777777,
      username: "Oleg",
      language: :go
    )
    assert subscription.valid?
    assert subscription.language_go?
  end

  test "language enum works for javascript" do
    subscription = Subscription.new(
      telegram_id: 88888888,
      username: "Kate",
      language: :javascript
    )
    assert subscription.valid?
    assert subscription.language_javascript?
  end

  test "language enum works for php" do
    subscription = Subscription.new(
      telegram_id: 99999999,
      username: "Max",
      language: :php
    )
    assert subscription.valid?
    assert subscription.language_php?
  end

  test "invalid language is rejected" do
    # Пытаемся сохранить несуществующий язык
    # В Rails 8 enum выбрасывает ArgumentError при присваивании неверного значения
    assert_raises(ArgumentError) do
      Subscription.new(
        telegram_id: 11111111,
        username: "Invalid",
        language: :csharp  # ❌ Нет в enum
      )
    end
  end

  # ============================== DATABASE TESTS ==============================

  test "can create and save subscription" do
    subscription = Subscription.create!(
      telegram_id: 123123123,
      username: "Saved",
      language: :ruby
    )
    assert subscription.persisted?
    assert_equal "ruby", subscription.language
  end

  test "can find subscription by telegram_id" do
    # Создаём подписку
    Subscription.create!(
      telegram_id: 321321321,
      username: "FindMe",
      language: :python
    )

    # Ищем по telegram_id
    found = Subscription.find_by(telegram_id: 321321321)
    assert_not_nil found
    assert_equal "FindMe", found.username
    assert found.language_python?
  end

  test "can update language" do
    # Создаём подписку с ruby
    subscription = Subscription.create!(
      telegram_id: 456456456,
      username: "Updater",
      language: :ruby
    )

    # Обновляем на python
    subscription.update!(language: :python)

    # Проверяем что обновилось
    assert subscription.language_python?
    assert_not subscription.language_ruby?
  end

  test "can destroy subscription" do
    subscription = Subscription.create!(
      telegram_id: 789789789,
      username: "Destroy",
      language: :java
    )

    # Запоминаем ID
    id = subscription.id

    # Удаляем
    subscription.destroy!

    # Проверяем что удалена
    assert_nil Subscription.find_by(id: id)
  end

  # ============================== ACTIVE RECORD TESTS ==============================

  test "created_at is set automatically" do
    subscription = Subscription.create!(
      telegram_id: 147147147,
      username: "Timestamp",
      language: :go
    )
    assert_not_nil subscription.created_at
    assert subscription.created_at <= Time.current
  end

  test "updated_at is updated on save" do
    subscription = Subscription.create!(
      telegram_id: 258258258,
      username: "Updated",
      language: :ruby
    )

    # Запоминаем старое updated_at
    old_updated_at = subscription.updated_at

    # Ждём немного и обновляем
    sleep 0.01
    subscription.update!(language: :python)

    # Проверяем что updated_at изменился
    assert subscription.updated_at > old_updated_at
  end
end
