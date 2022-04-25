# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed/heartbeat/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_job_heartbeat_plugin'
  spec.version       = Delayed::Heartbeat::VERSION
  spec.authors       = ['Joel Turkel']
  spec.email         = ['jturkel@salsify.com']

  spec.summary       = 'Delayed::Job plugin to unlock jobs from dead workers'
  spec.homepage      = 'https://github.com/salsify/delayed_job_heartbeat_plugin'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
    spec.metadata['rubygems_mfa_required'] = 'true'
  else
    raise 'RubyGems 2.0 or newer is required to set allowed_push_host.'
  end

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'delayed_job', '>= 4.1.0'
  spec.add_dependency 'delayed_job_active_record', '>= 4.1.0'

  spec.add_development_dependency 'activerecord', ['>= 5.2', '< 7.1']
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls_reborn', '>= 0.18.0'
  spec.add_development_dependency 'database_cleaner', '>= 1.2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'salsify_rubocop', '~> 1.0.2'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'timecop'
end
