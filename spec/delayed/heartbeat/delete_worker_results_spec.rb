require 'spec_helper'

describe Delayed::Heartbeat::DeleteWorkerResults do
  let(:worker) { create_worker(name: 'my-worker') }
  let(:job) { create_job(locked_by: worker.name) }
  let(:results) { create_results([worker], [job]) }

  describe "#workers" do
    specify { expect(results.workers).to eq [worker] }
  end

  describe "#unlocked_jobs" do
    specify { expect(results.unlocked_jobs).to eq [job] }
  end

  describe "#to_s" do
    it "includes workers" do
      results = create_results([worker], [])
      expect(results.to_s).to include(worker.name)
    end

    it "includes jobs for known workers" do
      results = create_results([worker], [job])
      expect(results.to_s).to include(job.id.to_s)
    end

    it "includes jobs locked by an unknown worker" do
      job = create_job(locked_by: 'unknown-worker')
      results = create_results([], [job])
      expect(results.to_s).to include(job.id.to_s)
      expect(results.to_s).to include(job.locked_by)
    end
  end

  def create_worker(attributes = {})
    Delayed::Heartbeat::Worker.create!(attributes)
  end

  def create_job(attributes = {})
    attributes = attributes.reverse_merge(payload_object: TestJob.new)
    Delayed::Job.create!(attributes)
  end

  def create_results(workers, unlocked_jobs)
    Delayed::Heartbeat::DeleteWorkerResults.new(workers, unlocked_jobs)
  end
end
