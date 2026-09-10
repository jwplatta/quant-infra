#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "es_futures_quotes" do
  provider :schwab
  symbols "/ES"
  schedule do
    daily
    windows [["17:00", "16:00"]]
    weekdays
  end
  level_one do
    services [:level_one_futures]
    flush_interval 300
    retention_days 30
  end
end
