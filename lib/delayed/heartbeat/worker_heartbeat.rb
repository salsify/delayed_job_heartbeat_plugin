module Delayed
  module Heartbeat
    class WorkerHeartbeat

      def initialize(worker_name)
        @worker_model = create_worker_model(worker_name)

        # Use a self-pipe to safely shutdown the heartbeat thread
        @stop_reader, @stop_writer = IO.pipe

        yield(self) if block_given?

        @heartbeat_thread = Thread.new { run_heartbeat_loop }
        # Make this a high priority thread to try to ensure it runs
        @heartbeat_thread.priority = 100
      end

      def alive?
        @heartbeat_thread.alive?
      end

      def stop
        # Use the self-pipe to tell the heartbeat thread to cleanly
        # shutdown
        if @stop_writer
          @stop_writer.close
          @stop_writer = nil
        end
      end

      private

      def create_worker_model(worker_name)
        Delayed::Heartbeat::Worker.transaction do
          Delayed::Heartbeat::Worker.where(name: worker_name).delete_all
          Delayed::Heartbeat::Worker.create!(name: worker_name)
        end
      end

      def run_heartbeat_loop
        loop do
          break if sleep_interruptibly(heartbeat_interval)
          update_heartbeat
          # Return the connection back to the pool since we won't be needing
          # it again for a while.
          Delayed::Backend::ActiveRecord::Job.clear_active_connections!
        end
      rescue => e
        # We don't want the worker to continue running if the heartbeat can't be written.
        # Don't use Thread.abort_on_exception because that will give Delayed::Job a chance
        # to mark the job as failed which will unlock it even though the clock
        # process has likely already unlocked it and another worker may have picked it up.
        Delayed::Heartbeat.configuration.on_worker_termination.call(@worker_model, e)
        exit(false)
      ensure
        @stop_reader.close
        @worker_model.delete
        # Note: The built-in Delayed::Plugins::ClearLocks will unlock the jobs for us
        Delayed::Backend::ActiveRecord::Job.clear_active_connections!
      end

      def update_heartbeat
        now = Time.now.utc
        heartbeat_delta_seconds = now - @worker_model.last_heartbeat_at
        if heartbeat_delta_seconds < heartbeat_timeout_seconds || self_termination_disabled?
          @worker_model.update_column(:last_heartbeat_at, now)
        else
          raise Timeout::Error, "Worker heartbeat not updated for #{heartbeat_delta_seconds} seconds which " \
              "exceeds timeout\n. Current job: #{ @worker_model.job.inspect}"
        end
      end

      def self_termination_disabled?
        !Delayed::Heartbeat.configuration.worker_termination_enabled?
      end

      def heartbeat_timeout_seconds
        Delayed::Heartbeat.configuration.heartbeat_timeout_seconds
      end

      def heartbeat_interval
        Delayed::Heartbeat.configuration.heartbeat_interval_seconds
      end

      # Returns a truthy if the sleep was interrupted
      def sleep_interruptibly(secs)
        IO.select([@stop_reader], nil, nil, secs)
      end
    end
  end
end
