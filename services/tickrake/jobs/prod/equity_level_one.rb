#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

# Level 1 quotes for SPY, QQQ, IWM.
# Regular market hours: Mon-Fri 08:30-15:00 CDT.
Tickrake.job "equity_level_one" do
  provider :schwab
  symbols "SPY", "QQQ", "IWM"
  schedule do
    every_day from: "08:30", to: "15:00"
  end
  level_one do
    services [:level_one_equities]
    rotation_interval 300
  end
end
