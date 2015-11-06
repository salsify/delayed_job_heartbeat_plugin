require 'set'

module Delayed
  module Heartbeat
    class Plugin < Delayed::Plugin

      callbacks do |lifecycle|
        lifecycle.before(:execute) do |worker|
          if Delayed::Heartbeat.configuration.enabled?
            @heartbeat = Delayed::Heartbeat::WorkerHeartbeat.new(worker.name)
          end
        end

        lifecycle.after(:execute) do |worker|
          @heartbeat.stop if @heartbeat
        end
      end

    end
  end
end

