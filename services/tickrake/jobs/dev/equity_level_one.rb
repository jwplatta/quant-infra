#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

# Level 1 quotes for SPY, QQQ, IWM.
# Regular market hours: Mon-Fri 09:30-16:00 ET.
Tickrake.job "equity_level_one" do
  provider :schwab
  symbols "SPY", "QQQ", "IWM"
  schedule do
    every_day from: "09:30", to: "16:00"
  end
  level_one do
    services [:level_one_equities]
    rotation_interval 300
  end
end
