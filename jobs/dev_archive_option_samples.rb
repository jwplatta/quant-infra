#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "archive_option_samples" do
  provider :schwab

  schedule do
    at "17:20"
    weekdays
  end

  maintenance do
    compact :option_samples, universe: "spx_symbols", delete_sources: true
    archive :option_samples, universe: "spx_symbols",
            to: :s3_archive, artifacts: %i[csv parquet],
            retain: { parquet: true }

    # compact :option_samples,
    #         universes: ["stock_option_symbols", "etf_option_symbols"],
    #         delete_sources: true
    # archive :option_samples,
    #         universes: ["stock_option_symbols", "etf_option_symbols"],
    #         to: :s3_archive, artifacts: %i[csv parquet],
    #         retain: { parquet: true }
  end
end
