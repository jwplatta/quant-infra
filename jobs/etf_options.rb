#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "etf_options" do
  provider :schwab
  universe "etf_option_symbols"

  schedule do
    every 10.minutes
    weekdays from: "08:30", to: "15:05"
  end

  options do
    dte(0..30)
  end
end
