#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "reconciler" do
  schedule do
    at "16:00"
    weekdays
  end

  reconcile do
    providers :schwab
  end
end
