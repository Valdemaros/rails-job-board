class TestRedisJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info ">>> TestRedisJob was performed at #{Time.current}"
  end
end
