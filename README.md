# Delayed Job Heartbeat Plugin

[![Gem Version](https://badge.fury.io/rb/delayed_job_heartbeat_plugin.png)][gem]
[![Build Status](https://secure.travis-ci.org/salsify/delayed_job_heartbeat_plugin.png?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/salsify/delayed_job_heartbeat_plugin.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/salsify/delayed_job_heartbeat_plugin/badge.png)][coveralls]

[gem]: https://rubygems.org/gems/delayed_job_heartbeat_plugin
[travis]: http://travis-ci.org/salsify/delayed_job_heartbeat_plugin
[codeclimate]: https://codeclimate.com/github/salsify/delayed_job_heartbeat_plugin
[coveralls]: https://coveralls.io/r/salsify/delayed_job_heartbeat_plugin

By default [Delayed Job](https://github.com/collectiveidea/delayed_job) uses the [ClearLocks](https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/plugins/clear_locks.rb) plugin to unlock jobs when a worker shuts down. Unfortunately this only works if a worker shuts down cleanly. If the worker crashes, the job won't be unlocked until `max_run_time` elapses which can cause unacceptable delays processing background jobs. Enter the Delayed Job Heartbeat Plugin...
 
The Delayed Job Heartbeat Plugin adds a heartbeat to all Delayed Job workers. After a configurable timeout jobs from unresponsive workers can be unlocked either via a Ruby API or a rake task. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_heartbeat_plugin'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayed_job_heartbeat_plugin

Run the required database migrations:

    $ rails generate delayed_job_heartbeat_plugin:install
    $ rake db:migrate

## Usage

There are two parts to using the Delayed Job Heartbeat Plugin:

* Configuring the worker's heartbeat options.
* Periodically unlocking jobs from unresponsive workers.

### Worker Heartbeat Options

The worker heartbeat can be configured in an initializer (e.g. `config/initializers/delayed_job_heartbeat.rb`) follows:

```ruby
Delayed::Heartbeat.configure do |configuration|
  configuration.enabled = Rails.env.production?
  configuration.heartbeat_interval_seconds = 60
  configuration.heartbeat_timeout_seconds = 180
  configuration.worker_termination_enabled = true
end
```

The plugin supports the following options (all of which are optional):

* `enabled` - enables/disables the plugin entirely (defaults to true in production and false in other environments)
* `worker_label` - a label for the worker. Consider setting this to `ENV['DYNO']` if running in Heroku to get the dyno's friendly name (defaults to the Delayed Job worker's name)
* `heartbeat_interval_seconds` - how often workers should send a heartbeat (defaults to 60 seconds)
* `heartbeat_timeout_seconds` - theshold after which workers are considered dead if they haven't heartbeated (defaults to 180 seconds)
* `worker_termination_enabled` - controls whether a worker that detects it has not heartbeated within the timeout period (e.g. due to severe memory swapping) should shut itself down (defaults to true in production and false in other environments)
* `on_worker_termination` - a callback proc that accepts a `Delayed::Heartbeat::Worker` and an `Exception` if the heartbeat fails. This can be useful for reporting to an error monitoring system. 
* `worker_version` - a version number of the worker's source code that is only used if you want to cleanup workers from old source code versions (defaults to `nil`)

### Unlocking Unresponsive Workers

Jobs from unresponsive workers can be unlocked by calling `Delayed::Heartbeat.delete_timed_out_workers` or running the `delayed:heartbeat:delete_timed_out_workers` rake task. This should be integrated with a scheduler like cron, [clockwork](https://github.com/tomykaira/clockwork) or the [Heroku Scheduler](https://devcenter.heroku.com/articles/scheduler) (if running in Heroku).

Jobs from workers running an old version of the source code can be unlocked by calling `Delayed::Heartbeat.delete_workers_with_different_version` or running the `delayed:heartbeat:delete_workers_with_different_version` rake task. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. 

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salsify/delayed_job_heartbeat_plugin.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
