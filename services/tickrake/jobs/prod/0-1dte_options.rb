#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "0-1dte_options" do
  provider :schwab
  universe "index_symbols"

  schedule do
    every 20.seconds
    weekdays from: "08:30", to: "15:00"
  end

  options do
    dte(0..1)
  end
end
