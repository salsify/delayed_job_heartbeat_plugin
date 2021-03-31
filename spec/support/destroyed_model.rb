# frozen_string_literal: true

RSpec::Matchers.define :have_been_destroyed do
  match do |actual|
    !actual.class.where(id: actual.id).exists?
  end

  description do
    'model should have been destroyed'
  end

  failure_message do |actual|
    "expected #{actual.class}(id: #{actual.id}) to have been destroyed"
  end
end
