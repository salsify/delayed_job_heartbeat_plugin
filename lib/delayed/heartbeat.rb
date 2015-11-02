require 'delayed/heartbeat/compatibility'
require 'delayed/heartbeat/configuration'
require 'delayed/heartbeat/plugin'
require 'delayed/heartbeat/version'
require 'delayed/heartbeat/worker'
require 'delayed/heartbeat/worker_heartbeat'

module Delayed
  module Heartbeat
    @configuration = Delayed::Heartbeat::Configuration.new

    class << self
      def configure
        yield(configuration) if block_given?
      end

      def configuration
        @configuration
      end

      def delete_workers_with_different_version(current_version = configuration.worker_version)
        old_workers = Delayed::Heartbeat::Worker.workers_with_different_version(current_version)
        cleanup_workers(old_workers, mark_attempt_failed: false)
      end

      def delete_timed_out_workers(timeout_seconds = configuration.heartbeat_timeout_seconds)
        dead_workers = Delayed::Heartbeat::Worker.dead_workers(timeout_seconds)
        cleanup_workers(dead_workers, mark_attempt_failed: true)
      end

      private

      def cleanup_workers(workers, mark_attempt_failed: true)
        Delayed::Heartbeat::Worker.transaction do
          orphaned_jobs = workers.flat_map do |worker|
            worker.unlock_jobs(mark_attempt_failed: mark_attempt_failed)
          end
          Delayed::Heartbeat::Worker.delete_workers(workers)
          [workers, orphaned_jobs]
        end
      end
    end
  end
end
