require 'active_support/version'
require 'active_record/version'

module Delayed
  module Heartbeat
    module Compatibility

      def self.mass_assignment_security_enabled?
        ::ActiveRecord::VERSION::MAJOR < 4 || defined?(::ActiveRecord::MassAssignmentSecurity)
      end

    end
  end
end
