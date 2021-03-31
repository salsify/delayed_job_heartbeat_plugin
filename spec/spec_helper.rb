# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
)
SimpleCov.start do
  add_filter 'spec'
end

require 'database_cleaner'
require 'delayed_job_heartbeat_plugin'
require 'yaml'
require 'timecop'

spec_dir = File.dirname(__FILE__)
Dir["#{spec_dir}/support/**/*.rb"].sort.each { |f| require f }

FileUtils.makedirs('log')
FileUtils.makedirs('tmp')

Delayed::Worker.read_ahead = 1
Delayed::Worker.destroy_failed_jobs = false

Delayed::Worker.logger = Logger.new('log/test.log')
Delayed::Worker.logger.level = Logger::DEBUG
ActiveRecord::Base.logger = Delayed::Worker.logger
ActiveRecord::Migration.verbose = false

database_name = 'delayed_job_heartbeat_plugin_test'
database_host = ENV.fetch('PGHOST', 'localhost')
database_port = ENV.fetch('PGPORT', 5432)

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    db_connection_args = "--host #{database_host} --port #{database_port}"
    `dropdb #{db_connection_args} --if-exists #{database_name} 2> /dev/null`
    `createdb #{db_connection_args} #{database_name}`

    pg_version = `psql #{db_connection_args} --dbname #{database_name} --tuples-only --command "select version()";`
    puts "Testing with Postgres version: #{pg_version.strip}"
    puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"

    database_url = "postgres://#{database_host}:#{database_port}/#{database_name}"
    puts "Using database #{database_url}"
    ActiveRecord::Base.establish_connection(database_url)
    require 'db/schema'
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do |example|
    DatabaseCleaner.strategy = example.metadata.fetch(:cleaner_strategy, :transaction)
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
