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

  spec.required_ruby_version = '>= 1.9'

  spec.add_dependency 'delayed_job', '>= 4.1.0'
  spec.add_dependency 'delayed_job_active_record', '>= 4.1.0'

  spec.add_development_dependency 'activerecord', ENV.fetch('RAILS_VERSION', ['>= 3.2', '< 5.1'])
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'database_cleaner', '>= 1.2'
  # rspec < 3.5 requires rake < 11.0
  spec.add_development_dependency 'rake', '< 11.0' 
  spec.add_development_dependency 'rspec', '3.3.0'
  spec.add_development_dependency 'simplecov', '~> 0.7.1'
  spec.add_development_dependency 'timecop'

  if RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'jdbc-sqlite3'
    spec.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    spec.add_development_dependency 'sqlite3', '~> 1.3.11'
  end
end
