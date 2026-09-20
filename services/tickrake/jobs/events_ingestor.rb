#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "events_ingestor" do
  schedule do
    every 60.seconds
  end
  events_ingest do
    batch_size 20
    datastore :s3_archive
  end
end
