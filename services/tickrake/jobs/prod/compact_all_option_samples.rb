#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "compact_all_option_samples" do
  provider :schwab

  schedule do
    at "15:10"
    weekdays
  end

  maintenance do
    compact :option_samples, universe: "0dte_symbols", delete_sources: true
    compact :option_samples,
            universes: ["stock_option_symbols", "etf_option_symbols"],
            delete_sources: true
  end
end
