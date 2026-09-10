#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "spx_short_options" do
  provider :schwab
  universe "spx_symbols"

  schedule do
    every 10.minutes
    weekdays from: "08:30", to: "15:05"
  end

  options do
    dte 0, 1, 2, 7
  end
end
