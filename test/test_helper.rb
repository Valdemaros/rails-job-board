ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

# Настройки для тестов
class ActiveSupport::TestCase
  # Транзакции: каждый тест откатывается после завершения
  self.use_transactional_tests = true

  # Фикстуры (если понадобятся)
  fixtures :all
end
