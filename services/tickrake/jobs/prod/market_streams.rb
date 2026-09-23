#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "market_streams" do
  provider :schwab

  stream do
    stale_timeout 60

    level_one "equity_level_one" do
      symbols "SPY", "QQQ", "IWM"
      services [:level_one_equities]
      rotation_interval 300
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    order_book "equity_order_book" do
      symbols "SPY", "QQQ", "IWM"
      services [:NYSE_BOOK, :NASDAQ_BOOK]
      rotation_interval 300
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    chart_stream "spx_chart_stream" do
      symbols "$SPX"
      services [:chart_equity]
      flush_interval 60
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    level_one "futures_level_one" do
      symbols "/ES"
      services [:level_one_futures]
      rotation_interval 300
      schedule do
        days %w[sun mon tue wed thu], from: "17:00", to: "23:59"
        days %w[mon tue wed thu fri], from: "00:00", to: "16:00"
      end
    end

    chart_stream "futures_chart_stream" do
      symbols "/ES"
      services [:chart_futures]
      flush_interval 60
      schedule do
        days %w[sun mon tue wed thu], from: "17:00", to: "23:59"
        days %w[mon tue wed thu fri], from: "00:00", to: "16:00"
      end
    end
  end
end
