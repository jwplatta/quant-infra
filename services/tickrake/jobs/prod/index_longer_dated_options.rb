#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "index_longer_dated_options" do
  provider :schwab
  universe "index_symbols"

  schedule do
    every 10.minutes
    weekdays from: "06:32", to: "08:22"
    weekdays from: "08:32", to: "15:12"
  end

  options do
    dte(11..60)
  end
end
