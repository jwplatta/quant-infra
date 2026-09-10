#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "compact_spxw" do
  provider :schwab

  schedule do
    at "15:10"
    weekdays
  end

  maintenance do
    compact :option_samples, universe: "spx_symbols", delete_sources: true
    archive :option_samples, universe: "spx_symbols",
            to: :s3_archive, artifacts: %i[csv parquet],
            retain: { parquet: true }
  end
end
