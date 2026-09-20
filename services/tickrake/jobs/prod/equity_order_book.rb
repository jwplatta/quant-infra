#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

# Order book (Level 2) for SPY, QQQ, IWM.
# Regular market hours: Mon-Fri 08:30-15:00 CDT.
Tickrake.job "equity_order_book" do
  provider :schwab
  symbols "SPY", "QQQ", "IWM"
  schedule do
    every_day from: "08:30", to: "15:00"
  end
  order_book do
    services [:NYSE_BOOK, :NASDAQ_BOOK]
    rotation_interval 300
  end
end
