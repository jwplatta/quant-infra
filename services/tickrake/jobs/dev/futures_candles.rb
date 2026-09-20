#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "dev_futures_candles" do
  provider :schwab
  symbols "/ES", "/NQ"
  lookback 90.days

  schedule do
    at "16:30"
    weekdays
  end

  candles do
    frequencies "day", "30min"
    start_date "2026-06-01"
  end
end
