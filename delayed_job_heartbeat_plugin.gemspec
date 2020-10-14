# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
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

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'delayed_job', '>= 4.1.0'
  spec.add_dependency 'delayed_job_active_record', '>= 4.1.0'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'activerecord', ['>= 5.2', '< 6.1']
  spec.add_development_dependency 'coveralls_reborn', '>= 0.18.0'
  spec.add_development_dependency 'database_cleaner', '>= 1.2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'timecop'
end
