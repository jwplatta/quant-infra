#!/usr/bin/env ruby
# frozen_string_literal: true

require "tickrake"

Tickrake.job "reconciler" do
  provider :schwab

  schedule do
    at "22:00"
    weekdays
  end

  reconcile do
    providers :schwab
  end
end
