#!/usr/bin/env ruby
# frozen_string_literal: true

# One-shot DSL job for a single option-sample date.
#
# Usage:
#   ruby compact_all_option_samples_for_date.rb 2026-09-21

require "date"
require "tickrake"

usage = "Usage: ruby compact_all_option_samples_for_date.rb YYYY-MM-DD"
abort usage unless ARGV.length == 1

begin
  sample_date = Date.iso8601(ARGV.fetch(0))
rescue Date::Error
  abort usage
end

Tickrake.job "compact_all_option_samples_for_date" do
  provider :schwab

  maintenance do
    start_date sample_date
    end_date sample_date

    compact :option_samples, universe: "spx_symbols", delete_sources: true
    archive :option_samples, universe: "spx_symbols",
            to: :s3_archive, artifacts: %i[csv parquet],
            retain: { parquet: true }

    compact :option_samples,
            universes: ["stock_option_symbols", "etf_option_symbols"],
            delete_sources: true
    archive :option_samples,
            universes: ["stock_option_symbols", "etf_option_symbols"],
            to: :s3_archive, artifacts: %i[csv parquet],
            retain: { parquet: true }
  end
end
