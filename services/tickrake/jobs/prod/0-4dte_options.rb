#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "0-4dte_options" do
  provider :schwab
  universe "index_symbols"

  schedule do
    every 30.seconds
    weekdays from: "06:30", to: "08:20"
    weekdays from: "08:30", to: "15:10"
  end

  options do
    dte(0..4)
  end
end
