require 'delayed/heartbeat/compatibility'
require 'delayed/heartbeat/configuration'
require 'delayed/heartbeat/delete_worker_results'
require 'delayed/heartbeat/plugin'
require 'delayed/heartbeat/version'
require 'delayed/heartbeat/worker'
require 'delayed/heartbeat/worker_heartbeat'
require 'delayed/heartbeat/railtie' if defined?(Rails::Railtie)

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
        cleanup_workers(old_workers, false)
      end

      def delete_timed_out_workers(timeout_seconds = configuration.heartbeat_timeout_seconds)
        dead_workers = Delayed::Heartbeat::Worker.dead_workers(timeout_seconds)
        cleanup_workers(dead_workers, true)
      end

      private

      def cleanup_workers(workers, mark_attempt_failed = true)
        Delayed::Heartbeat::Worker.transaction do
          worker_job_map = workers.each_with_object(Hash.new) do |worker, worker_job_map|
            worker_job_map[worker] = worker.unlock_jobs(mark_attempt_failed)
          end
          Delayed::Heartbeat::Worker.delete_workers(workers)
          Delayed::Heartbeat::DeleteWorkerResults.new(worker_job_map)
        end
      end
    end
  end
end
