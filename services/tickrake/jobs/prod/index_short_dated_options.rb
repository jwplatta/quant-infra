#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "index_short_dated_options" do
  provider :schwab
  universe "index_symbols"

  schedule do
    every 5.minutes
    weekdays from: "06:31", to: "8:25"
    weekdays from: "08:31", to: "15:15"
  end

  options do
    dte(5..10)
  end
end
