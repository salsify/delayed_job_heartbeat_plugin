# frozen_string_literal: true

require 'set'

module Delayed
  module Heartbeat
    class Plugin < Delayed::Plugin

      callbacks do |lifecycle|
        lifecycle.before(:execute) do |worker|
          @heartbeat = Delayed::Heartbeat::WorkerHeartbeat.new(worker.name) if Delayed::Heartbeat.configuration.enabled?
        end

        lifecycle.after(:execute) do |_worker|
          @heartbeat.stop if @heartbeat
        end
      end

    end
  end
end
