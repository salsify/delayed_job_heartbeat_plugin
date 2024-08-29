# frozen_string_literal: true

namespace :delayed do
  namespace :heartbeat do
    desc 'Cleans up workers that have not heartbeated recently.'
    task delete_timed_out_workers: :environment do
      results = Delayed::Heartbeat.delete_timed_out_workers
      print_results(results)
    end

    desc 'Cleans up workers running a different version.'
    task delete_workers_with_different_version: :environment do
      results = Delayed::Heartbeat.delete_workers_with_different_version
      print_results(results)
    end

    def print_results(results)
      puts "Deleted #{results.workers.size} and unlocked #{results.unlocked_jobs.size} orphaned jobs"
      puts results if verbose? && results.present?
    end

    def verbose?
      ENV['VERBOSE'].to_s.casecmp('true').zero?
    end
  end
end
