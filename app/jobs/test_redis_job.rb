class TestRedisJob
  include Sidekiq::Job

  def perform
    Rails.logger.info ">>> TestRedisJob was performed at #{Time.current}"
  end
end
