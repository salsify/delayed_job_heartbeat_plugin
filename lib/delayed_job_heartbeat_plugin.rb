# frozen_string_literal: true

require 'active_support'
require 'active_record'
require 'delayed_job'
require 'delayed_job_active_record'
require 'delayed/heartbeat'

Delayed::Worker.plugins << Delayed::Heartbeat::Plugin
