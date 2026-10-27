#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "staging_publisher" do
  schedule do
    at "16:05"
    weekdays
  end

  staging_publish do
    datasets :all
    delete_after_upload false
  end
end
