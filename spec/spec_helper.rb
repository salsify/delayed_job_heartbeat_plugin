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
require 'pg'

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

database_host = ENV.fetch('DB_HOST', 'localhost')
database_port = ENV.fetch('DB_PORT', 5432)
database_user = ENV.fetch('DB_USER', 'postgres')
database_password = ENV.fetch('DB_PASSWORD', 'password')
database_url = "postgres://#{database_user}:#{database_password}@#{database_host}:#{database_port}"
admin_database_name = "/#{ENV['ADMIN_DB_NAME']}" if ENV['ADMIN_DB_NAME'].present?

DATABASE_NAME = 'delayed_job_heartbeat_plugin_test'

def setup_test_database(pg_conn, database_name)
  pg_conn.exec("DROP DATABASE IF EXISTS #{database_name}")
  pg_conn.exec("CREATE DATABASE #{database_name}")

  pg_version = pg_conn.exec('SELECT version()')
  puts "Testing with Postgres version: #{pg_version.getvalue(0, 0)}"
  puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"
end

def teardown_test_database(pg_conn, database_name)
  pg_conn.exec("DROP DATABASE IF EXISTS #{database_name}")
end

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    PG::Connection.open("#{database_url}#{admin_database_name}") do |connection|
      setup_test_database(connection, DATABASE_NAME)
    end

    ActiveRecord::Base.establish_connection("#{database_url}/#{DATABASE_NAME}")

    require 'db/schema'
  end

  config.after(:suite) do
    ActiveRecord::Base.connection_pool.disconnect!

    PG::Connection.open("#{database_url}#{admin_database_name}") do |connection|
      teardown_test_database(connection, DATABASE_NAME)
    end
  end

  config.before do |example|
    DatabaseCleaner.strategy = example.metadata.fetch(:cleaner_strategy, :transaction)
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
