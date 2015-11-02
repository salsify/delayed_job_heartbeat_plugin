require 'spec_helper'

describe Delayed::Heartbeat::WorkerHeartbeat, cleaner_strategy: :truncation do
  let(:worker_name) { 'Test Worker' }
  let(:worker_model) { find_worker_model(worker_name) }
  let(:heartbeat_config) do
    Delayed::Heartbeat::Configuration.new(heartbeat_interval_seconds: 0.001)
  end

  before do
    allow(Delayed::Heartbeat).to receive(:configuration).and_return(heartbeat_config)

    Delayed::Job.create!(locked_by: worker_name, payload_object: TestJob.new)
    @worker_heartbeat = start_heartbeat
  end

  after do
    stop_heartbeat
  end

  it "creates a worker model" do
    expect(worker_model).to be_present
  end

  it "updates the worker heartbeat" do
    original_heartbeat = worker_model.last_heartbeat_at
    Wait.for('worker heartbeat updated') do
      worker_model.reload.last_heartbeat_at != original_heartbeat
    end
  end

  context "when the heartbeat is stopped" do
    let!(:job) { Delayed::Backend::ActiveRecord::Job.create!(locked_by: worker_model.name, locked_at: Time.now) }

    before do
      stop_heartbeat
    end

    it "destroys the worker model" do
      expect(find_worker_model(worker_name)).not_to be_present
    end
  end

  context "when the heartbeat times out" do
    let(:heartbeat_config) do
      # Create a configuration where heartbeat is updated less frequently than the timeout
      Delayed::Heartbeat::Configuration.new(heartbeat_interval_seconds: 0.001,
                                            heartbeat_timeout_seconds: 0.00000001,
                                            worker_termination_enabled: true)
    end

    before do
      wait_for_heartbeat_thread_stopped
    end

    it "aborts the process" do
      expect(@worker_heartbeat).to have_received(:exit).with(false)
    end

    def start_heartbeat
      Delayed::Heartbeat::WorkerHeartbeat.new(worker_name) do |heartbeat|
        allow(heartbeat).to receive(:exit)
      end
    end
  end

  def start_heartbeat
    Delayed::Heartbeat::WorkerHeartbeat.new(worker_name)
  end

  def stop_heartbeat
    @worker_heartbeat.stop
    wait_for_heartbeat_thread_stopped
  end

  def wait_for_heartbeat_thread_stopped
    Wait.for('worker thread stopped') do
      !@worker_heartbeat.alive?
    end
  end

  def find_worker_model(worker_name)
    Delayed::Heartbeat::Worker.where(name: worker_name).first
  end
end
