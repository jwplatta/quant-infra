#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "intraday_publisher" do
  schedule do
    every 60.seconds
    weekdays from: "06:30", to: "15:15"
  end
end
