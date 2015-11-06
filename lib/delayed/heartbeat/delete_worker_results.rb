module Delayed
  module Heartbeat
    class DeleteWorkerResults
      attr_reader :workers, :unlocked_jobs

      def initialize(workers, unlocked_jobs)
        @workers = workers
        @unlocked_jobs = unlocked_jobs
      end

      def empty?
        workers.empty? && unlocked_jobs.empty?
      end

      def to_s
        io = StringIO.new
        workers.each do |worker|
          io.puts("Deleted worker #{worker_description(worker)}")
        end

        unlocked_jobs.each do |unlocked_job|
          worker = worker_map[unlocked_job.locked_by]
          worker_string = worker ? worker_description(worker) : unlocked_job.locked_by
          io.puts("Unlocked orphaned job #{unlocked_job.id} from worker #{worker_string}")
        end

        io.string
      end

      private

      def worker_map
        @worker_map ||= workers.each_with_object(Hash.new) do |worker, worker_map|
          worker_map[worker.name] = worker
        end
      end

      def worker_description(worker)
        "#{worker.label}(#{worker.name})"
      end
    end
  end
end
