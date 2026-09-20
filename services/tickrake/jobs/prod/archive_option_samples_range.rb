#!/usr/bin/env ruby
# frozen_string_literal: true

# One-shot archive script for a specific option root and date range.
#
# Usage:
#   ruby archive_option_samples_range.rb \
#     --roots SPXW,AAPL,NVDA --start-date 2026-08-01 --end-date 2026-08-31
#
#   For a single date, set --start-date and --end-date to the same value.

require "tickrake"
require "date"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.on("--roots ROOTS", "Comma-separated option root tickers (e.g. SPXW,AAPL,NVDA)") { |v| options[:roots] = v.split(",").map(&:strip) }
  opts.on("--start-date DATE", "Start sample date (YYYY-MM-DD)") { |v| options[:start_date] = Date.iso8601(v) }
  opts.on("--end-date DATE",   "End sample date (YYYY-MM-DD)")   { |v| options[:end_date]   = Date.iso8601(v) }
  opts.on("--provider NAME",   "Provider name (default: schwab)") { |v| options[:provider]  = v }
end.parse!

abort "ERROR: --roots is required (e.g. --roots SPXW,AAPL)" if options[:roots].nil? || options[:roots].empty?
abort "ERROR: --start-date is required"        unless options[:start_date]
abort "ERROR: --end-date is required"          unless options[:end_date]

provider = options.fetch(:provider, "schwab")

config  = Tickrake::ConfigLoader.load(ENV.fetch("TICKRAKE_CONFIG"))
tracker = Tickrake::Tracker.new(config.sqlite_path)
logger  = Logger.new($stdout)
logger.level = Logger::INFO

runtime = Tickrake::Runtime.new(
  config: config,
  tracker: tracker,
  client_factory: nil,
  logger: logger
)

options[:roots].each do |root|
  logger.info("archive_range: processing root=#{root} #{options[:start_date]}..#{options[:end_date]}")

  scheduled_job = Tickrake::ScheduledJobConfig.new(
    name:             "archive_option_samples_range",
    type:             "maintenance",
    provider:         provider,
    interval_seconds: nil,
    windows:          [],
    run_at:           nil,
    days:             [],
    lookback_days:    nil,
    dte_buckets:      [],
    universe:         [],
    tasks: [
      Tickrake::MaintenanceStepConfig.new(
        action:         "compact",
        subject:        "option_samples",
        provider:       provider,
        universe:       nil,
        universes:      [],
        tickers:        [],
        option_root:    root,
        delete_sources: true,
        destination:    nil,
        artifacts:      [],
        retain_local:   {}
      ),
      Tickrake::MaintenanceStepConfig.new(
        action:         "archive",
        subject:        "option_samples",
        provider:       provider,
        universe:       nil,
        universes:      [],
        tickers:        [],
        option_root:    root,
        delete_sources: false,
        destination:    "s3_archive",
        artifacts:      %w[csv parquet],
        retain_local:   { "csv" => false, "parquet" => true }
      )
    ],
    task:     nil,
    settings: {},
    manual:   true
  )

  result = Tickrake::MaintenanceJob.new(
    runtime,
    scheduled_job: scheduled_job,
    start_date:    options[:start_date],
    end_date:      options[:end_date]
  ).run(now: Time.now)

  if result.successful?
    logger.info("archive_range: #{root} done artifacts=#{result.artifacts_written.length}")
  else
    logger.error("archive_range: #{root} failed")
    result.step_results.each do |sr|
      sr.errors.each { |e| logger.error("  #{sr.action}: #{e}") }
    end
  end
end
