#!/usr/bin/env ruby
# frozen_string_literal: true

# One-shot script to drain all pending metadata sidecars into the SQLite cache.
# Useful for backfilling after downtime or recovering from errors.
#
# Usage:
#   TICKRAKE_CONFIG=~/.tickrake-dev/tickrake-dev.yml ruby scripts/drain_pending_metadata.rb
#   TICKRAKE_CONFIG=~/.tickrake/tickrake.yml ruby scripts/drain_pending_metadata.rb
#
# Options (via env):
#   BATCH_SIZE=1000   — files per batch (default: 500)

require "tickrake"

Tickrake.job "drain_pending_metadata" do
  metadata_sync do
    batch_size Integer(ENV.fetch("BATCH_SIZE", "500"))
  end
end
