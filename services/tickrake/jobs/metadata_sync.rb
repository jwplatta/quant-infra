#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "metadata_sync" do
  schedule do
    every 30.seconds
    weekdays from: "08:00", to: "16:00"
  end

  metadata_sync do
    batch_size 500
  end
end
