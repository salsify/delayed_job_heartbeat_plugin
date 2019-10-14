require 'delayed/heartbeat/compatibility'

module Delayed
  module Heartbeat
    class Worker < ActiveRecord::Base
      self.table_name = 'delayed_workers'

      if Delayed::Heartbeat::Compatibility.mass_assignment_security_enabled?
        attr_accessible :name, :version, :last_heartbeat_at, :host_name, :label
      end

      before_create do |model|
        model.last_heartbeat_at ||= Time.now.utc
        model.host_name ||= Socket.gethostname
        model.label ||= Delayed::Heartbeat.configuration.worker_label || name
        model.version ||= Delayed::Heartbeat.configuration.worker_version
      end

      def jobs
        Delayed::Job.where(locked_by: name, failed_at: nil)
      end

      def job
        jobs.first
      end

      # Returns the jobs that were unlocked
      def unlock_jobs(mark_attempt_failed = true)
        orphaned_jobs = jobs.to_a
        return orphaned_jobs unless orphaned_jobs.present?

        if mark_attempt_failed
          mark_job_attempts_failed(orphaned_jobs)
        else
          Delayed::Job.where(id: orphaned_jobs.map(&:id)).update_all(locked_at: nil, locked_by: nil)
        end

        orphaned_jobs
      end

      def self.dead_workers(timeout_seconds)
        where('last_heartbeat_at < ?', Time.now.utc - timeout_seconds)
      end

      def self.workers_with_different_version(current_version)
        where('version != ?',  current_version)
      end

      def self.delete_workers(workers)
        where(id: workers.map(&:id)).delete_all if workers.present?
      end

      private

      def mark_job_attempts_failed(jobs)
        dj_worker = Delayed::Worker.new
        jobs.each do |job|
          mark_job_attempt_failed(dj_worker, job)
        end
      end

      def mark_job_attempt_failed(dj_worker, job)
        # If there are more attempts this reschedules the job otherwise marks it as failed
        # and runs appropriate callbacks
        dj_worker.reschedule(job)
      end
    end
  end
end
