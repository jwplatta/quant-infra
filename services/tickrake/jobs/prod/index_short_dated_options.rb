#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "index_short_dated_options" do
  provider :schwab
  universe "index_symbols"

  schedule do
    every 2.minutes
    weekdays from: "08:30", to: "15:05"
  end

  options do
    dte(2..10)
  end
end
