#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "spx_0dte_options" do
  provider :schwab
  universe "spx_symbols"

  schedule do
    every 5.seconds
    weekdays from: "08:30", to: "15:00"
  end

  options do
    dte 0
  end
end
