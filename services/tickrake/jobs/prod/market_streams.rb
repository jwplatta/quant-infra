#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "market_streams" do
  provider :schwab

  stream do
    stale_timeout 60

    level_one "equity_level_one" do
      universe "equity_symbols"
      services [:level_one_equities]
      rotation_size_mb 512
      rotation_interval 3600
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    order_book "equity_order_book" do
      universe "equity_symbols"
      services [:NYSE_BOOK, :NASDAQ_BOOK]
      rotation_size_mb 512
      rotation_interval 3600
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    chart_stream "equity_chart_streams" do
      symbols "$SPX", "$VIX"
      services [:chart_equity]
      flush_interval 120
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    level_one "futures_level_one" do
      symbols "/ES", "/NQ", "/CL", "/ZB", "/ZN", "/6E", "/ZC", "/ZS", "/ZW", "/NG", "/GC", "/SI", "/RTY", "/YM", "/HG"
      services [:level_one_futures]
      rotation_size_mb 512
      rotation_interval 3600
      schedule do
        days %w[sun mon tue wed thu], from: "17:00", to: "23:59"
        days %w[mon tue wed thu fri], from: "00:00", to: "16:00"
      end
    end

    chart_stream "futures_chart_streams" do
      symbols "/ES", "/NQ", "/RTY"
      services [:chart_futures]
      flush_interval 120
      schedule do
        days %w[sun mon tue wed thu], from: "17:00", to: "23:59"
        days %w[mon tue wed thu fri], from: "00:00", to: "16:00"
      end
    end
  end
end
