#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "intraday_publisher" do
  schedule do
    every 60.seconds
    weekdays from: "08:30", to: "15:30"
  end

  intraday_publish do
    datastore :minio_intraday
  end
end
