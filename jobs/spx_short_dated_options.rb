#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "spx_short_dated_options" do
  provider :schwab
  universe "spx_symbols"

  schedule do
    every 60.seconds
    weekdays from: "08:30", to: "15:05"
  end

  options do
    dte(1..10)
  end
end
