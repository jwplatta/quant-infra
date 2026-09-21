#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "economic_events" do
  schedule do
    at "06:00"
    every_day
  end

  economic_events do
    lookback_days 30
    lookahead_days 90
    categories "economic", "earnings", "fomc"
  end
end
