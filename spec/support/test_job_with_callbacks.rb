# frozen_string_literal: true

class TestJobWithCallbacks
  cattr_accessor :called_callbacks
  self.called_callbacks = []

  def self.clear
    called_callbacks.clear
  end

  def failure(*)
    self.class.called_callbacks << :failure
  end

  def perform
    self.class.called_callbacks << :perform
  end
end
