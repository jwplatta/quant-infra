#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "stock_options_high_frequency" do
  provider :schwab
  universe "stock_options_high_frequency_symbols"

  schedule do
    every 5.minutes
    weekdays from: "08:34", to: "15:04"
  end

  options do
    dte(0..30)
  end
end
