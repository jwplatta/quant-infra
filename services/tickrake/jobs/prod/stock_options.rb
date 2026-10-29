#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "stock_options" do
  provider :schwab
  universe "stock_options_standard_frequency_symbols"

  schedule do
    every 10.minutes
    weekdays from: "08:35", to: "15:05"
  end

  options do
    dte(0..30)
  end
end
