#!/usr/bin/env ruby
# frozen_string_literal: true

# One-shot script to compact and archive option chain samples for a date range.
#
# Usage:
#   TICKRAKE_CONFIG=~/.tickrake/tickrake.yml ruby scripts/archive_option_samples.rb \
#     --start-date 2026-09-01 --end-date 2026-09-17
#
#   For a single date:
#     --start-date 2026-09-17 --end-date 2026-09-17

require "tickrake"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.on("--start-date DATE", "Start sample date (YYYY-MM-DD)") { |v| options[:start_date] = v }
  opts.on("--end-date DATE",   "End sample date (YYYY-MM-DD)")   { |v| options[:end_date]   = v }
end.parse!

abort "ERROR: --start-date and --end-date are required" unless options[:start_date] && options[:end_date]

Tickrake.job "archive_option_samples" do
  provider :schwab

  maintenance do
    start_date options[:start_date]
    end_date   options[:end_date]

    compact :option_samples, universe: "spx_symbols", delete_sources: true
    archive :option_samples, universe: "spx_symbols",
            to: :s3_archive,
            artifacts: %i[csv parquet],
            retain: { csv: false, parquet: true }

    compact :option_samples, universes: %w[stock_option_symbols etf_option_symbols], delete_sources: true
    archive :option_samples, universes: %w[stock_option_symbols etf_option_symbols],
            to: :s3_archive,
            artifacts: %i[csv parquet],
            retain: { csv: false, parquet: true }
  end
end
