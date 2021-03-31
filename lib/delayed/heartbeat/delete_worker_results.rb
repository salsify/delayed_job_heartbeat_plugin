# frozen_string_literal: true

module Delayed
  module Heartbeat
    class DeleteWorkerResults
      def initialize(worker_job_map)
        @worker_job_map = worker_job_map
      end

      def workers
        @worker_job_map.keys
      end

      def unlocked_jobs(worker = nil)
        worker ? @worker_job_map.fetch(worker, []) : @worker_job_map.values.flatten
      end

      def empty?
        @worker_job_map.empty?
      end

      def to_s
        io = StringIO.new
        workers.each do |worker|
          worker_description = "#{worker.label}(#{worker.name})"
          io.puts("Deleted worker #{worker_description}")
          unlocked_jobs(worker).each do |unlocked_job|
            io.puts("Unlocked orphaned job #{unlocked_job.id} from worker #{worker_description}")
          end
        end
        io.string.rstrip
      end
    end
  end
end
