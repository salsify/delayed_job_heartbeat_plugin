require 'spec_helper'

describe Delayed::Heartbeat::DeleteWorkerResults do
  let(:worker) { create_worker(name: 'my-worker') }
  let(:job) { create_job(locked_by: worker.name) }
  let(:results) { create_results(worker => [job]) }

  describe "#workers" do
    specify { expect(results.workers).to eq [worker] }
  end

  describe "#unlocked_jobs" do
    let(:other_worker) { create_worker(name: 'my-other-worker') }
    let(:other_job) { create_job(locked_by: worker.name) }
    let(:results) { create_results(worker => [job], other_worker => [other_job]) }

    specify { expect(results.unlocked_jobs(worker)).to eq [job] }
    specify { expect(results.unlocked_jobs).to match_array [job, other_job] }
  end

  describe "#to_s" do
    it "includes workers" do
      results = create_results(worker => [])
      expect(results.to_s).to include(worker.name)
    end

    it "includes jobs for workers" do
      expect(results.to_s).to include(job.id.to_s)
    end
  end

  def create_worker(attributes = {})
    Delayed::Heartbeat::Worker.create!(attributes)
  end

  def create_job(attributes = {})
    attributes = attributes.reverse_merge(payload_object: TestJob.new)
    Delayed::Job.create!(attributes)
  end

  def create_results(worker_job_map)
    Delayed::Heartbeat::DeleteWorkerResults.new(worker_job_map)
  end
end
