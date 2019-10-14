require 'spec_helper'

describe Delayed::Heartbeat do
  let(:current_version) { 'current version' }
  let!(:active_worker) { create_worker_model(name: 'active_worker', version: current_version) }

  let!(:active_job) do
    Delayed::Job.create!(locked_by: active_worker.name,
                         locked_at: active_worker.last_heartbeat_at,
                         payload_object: TestJob.new)
  end

  let!(:orphaned_job) do
    Delayed::Job.create!(locked_by: dead_worker.name,
                         locked_at: dead_worker.last_heartbeat_at,
                         payload_object: TestJob.new)
  end

  shared_examples "it destroys a worker and unlocks its jobs" do |expected_orphaned_job_attempts|
    specify { expect(active_worker).not_to have_been_destroyed }
    specify { expect(active_job.reload.locked_by).not_to be_nil }
    specify { expect(active_job.reload.locked_at).not_to be_nil }
    specify { expect(active_job.reload.attempts).to eq(0) }
    specify { expect(active_job.reload.failed_at).to be_nil }

    specify { expect(dead_worker).to have_been_destroyed }
    specify { expect(orphaned_job.reload.locked_by).to be_nil }
    specify { expect(orphaned_job.reload.locked_at).to be_nil }
    specify { expect(orphaned_job.reload.attempts).to eq(expected_orphaned_job_attempts) }
    specify { expect(orphaned_job.reload.failed_at).to be_nil }
  end

  describe ".delete_timed_out_workers" do
    let!(:dead_worker) do
      create_worker_model(name: 'dead_worker',
                          last_heartbeat_at: Time.now - Delayed::Heartbeat.configuration.heartbeat_timeout_seconds - 1)
    end

    let(:max_attempts) { 5 }

    let!(:failed_orphaned_job) do
      Delayed::Job.create!(locked_by: dead_worker.name, locked_at: dead_worker.last_heartbeat_at,
          payload_object: TestJobWithCallbacks.new) do |job|
        job.attempts = max_attempts - 1
      end
    end

    before do
      TestJobWithCallbacks.clear
      @old_attempts = Delayed::Worker.max_attempts
      Delayed::Worker.max_attempts = max_attempts

      Delayed::Heartbeat.delete_timed_out_workers
    end

    after do
      Delayed::Worker.max_attempts = @old_attempts
    end

    specify { expect(failed_orphaned_job.reload.failed_at).to be_present }
    specify { expect(TestJobWithCallbacks.called_callbacks).to eq [:failure] }

    it_behaves_like "it destroys a worker and unlocks its jobs", 1
  end

  describe ".delete_workers_with_different_version" do
    let!(:dead_worker) { create_worker_model(name: 'old_worker', version: 'old version') }

    before do
      Delayed::Heartbeat.delete_workers_with_different_version(current_version)
    end

    it_behaves_like "it destroys a worker and unlocks its jobs", 0
  end

  def create_worker_model(attributes)
    Delayed::Heartbeat::Worker.create!(attributes)
  end

end


