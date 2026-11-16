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
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    order_book "equity_order_book" do
      universe "equity_symbols"
      services [:NYSE_BOOK, :NASDAQ_BOOK]
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    level_one "spxw_0dte_level_one" do
      services [:level_one_options]
      contracts do
        underlying "SPX"
        option_root "SPXW"
        atm_points 50
        expirations front: 1
        re_resolve_interval 5
      end
      schedule do
        weekdays from: "06:30", to: "08:20"
        weekdays from: "08:30", to: "15:00"
      end
    end

    order_book "spxw_0dte_order_book" do
      services [:OPTIONS_BOOK]
      contracts do
        underlying "SPX"
        option_root "SPXW"
        atm_points 50
        expirations front: 1
        re_resolve_interval 5
      end
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    level_one "spy_0dte_level_one" do
      services [:level_one_options]
      contracts do
        underlying "SPY"
        atm_points 10
        expirations front: 1
        re_resolve_interval 5
      end
      schedule do
        weekdays from: "06:30", to: "08:20"
        weekdays from: "08:30", to: "15:00"
      end
    end

    order_book "spy_0dte_order_book" do
      services [:OPTIONS_BOOK]
      contracts do
        underlying "SPY"
        atm_points 10
        expirations front: 1
        re_resolve_interval 5
      end
      schedule { weekdays from: "08:30", to: "15:00" }
    end

    level_one "qqq_0dte_level_one" do
      services [:level_one_options]
      contracts do
        underlying "QQQ"
        atm_points 10
        expirations front: 1
        re_resolve_interval 5
      end
      schedule do
        weekdays from: "06:30", to: "08:20"
        weekdays from: "08:30", to: "15:00"
      end
    end

    order_book "qqq_0dte_order_book" do
      services [:OPTIONS_BOOK]
      contracts do
        underlying "QQQ"
        atm_points 10
        expirations front: 1
        re_resolve_interval 5
      end
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
