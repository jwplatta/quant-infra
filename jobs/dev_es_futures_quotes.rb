#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

# /ES E-mini S&P 500 futures Level 1 quotes.
# CME session runs Sun 17:00 CT through Fri 16:00 CT with a daily 16:00-17:00 break.
# Split into two windows to cover both sides of midnight.
Tickrake.job "es_futures_quotes" do
  provider :schwab
  symbols "/ES"
  schedule do
    every_day from: "17:00", to: "23:59"
    every_day from: "00:00", to: "16:00"
  end
  level_one do
    services [:level_one_futures]
    rotation_interval 900
  end
end
