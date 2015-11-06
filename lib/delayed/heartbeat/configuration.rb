module Delayed
  module Heartbeat
    class Configuration
      attr_accessor :enabled, :worker_label, :worker_version,
                    :heartbeat_timeout_seconds, :heartbeat_interval_seconds,
                    :worker_termination_enabled, :on_worker_termination
      alias_method :enabled?, :enabled
      alias_method :worker_termination_enabled?, :worker_termination_enabled

      def initialize(options = {})
        options.each do |key, value|
          send("#{key}=", value)
        end

        if enabled.nil?
          self.enabled = defined?(Rails) ? Rails.env.production? : true
        end

        if worker_termination_enabled.nil?
          self.worker_termination_enabled = defined?(Rails) ? Rails.env.production? : true
        end

        self.heartbeat_timeout_seconds ||= 180
        self.heartbeat_interval_seconds ||= 60
        self.on_worker_termination ||= Proc.new { }
      end
    end
  end
end
