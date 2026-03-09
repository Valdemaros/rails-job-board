class ApplicationJob < ActiveJob::Base
  # Solid Queue adapter (Rails 8)
  queue_as :default

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError
end
