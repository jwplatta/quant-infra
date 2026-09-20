#!/usr/bin/env ruby
# frozen_string_literal: true

# Diagnostic script for verifying the intraday storage pipeline:
#   1. Pending sidecars waiting to be ingested by metadata_sync
#   2. Today's file_metadata_cache entries (what metadata_sync has ingested)
#   3. Objects uploaded to Minio by intraday_publisher
#
# Usage:
#   TICKRAKE_CONFIG=~/.tickrake-dev/tickrake-dev.yml ruby scripts/check_intraday_storage.rb
#   TICKRAKE_CONFIG=~/.tickrake/tickrake.yml ruby scripts/check_intraday_storage.rb

$LOAD_PATH.unshift(File.expand_path("~/repos/tickrake/lib"))
require "tickrake"
require "aws-sdk-s3"

DEV_ENV_PATH = File.expand_path("~/repos/quant-infra/env/dev.env")
if File.exist?(DEV_ENV_PATH)
  File.readlines(DEV_ENV_PATH, chomp: true).each do |line|
    next if line.strip.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    ENV[key] ||= value
  end
end

CONFIG_PATH = File.expand_path(ENV.fetch("TICKRAKE_CONFIG", "~/.tickrake-dev/tickrake-dev.yml"))
TODAY = Date.today.iso8601

config = Tickrake::ConfigLoader.load(CONFIG_PATH)
tracker = Tickrake::Tracker.new(config.sqlite_path)

def section(title)
  puts "\n=== #{title} ==="
end

# ── 1. Pending sidecars ──────────────────────────────────────────────────────

section "Pending sidecars (not yet ingested)"

pending_dir = config.pending_metadata_dir
if Dir.exist?(pending_dir)
  sidecars = Dir.glob(File.join(pending_dir, "*.meta.json"))
  if sidecars.empty?
    puts "  (none — metadata_sync is keeping up)"
  else
    puts "  #{sidecars.length} sidecar(s) waiting:"
    sidecars.first(10).each { |p| puts "    #{File.basename(p)}" }
    puts "    ... and #{sidecars.length - 10} more" if sidecars.length > 10
  end
else
  puts "  pending_metadata_dir does not exist: #{pending_dir}"
end

# ── 2. file_metadata_cache — today's entries ─────────────────────────────────

section "file_metadata_cache — today's entries (#{TODAY})"

rows = tracker.file_metadata_rows(where: "date(last_observed_at) = '#{TODAY}' AND dataset_type = 'options'")

if rows.empty?
  puts "  (none — metadata_sync may not have run yet)"
else
  by_root = rows.group_by { |r| [r["provider_name"], r["ticker"]] }
  by_root.sort.each do |(provider, root), group|
    expirations = group.map { |r| r["expiration_date"] }.compact.uniq.sort
    total_rows = group.sum { |r| r["row_count"].to_i }
    puts "  #{provider}/#{root}: #{group.length} file(s), #{expirations.length} expiration(s), #{total_rows} rows"
  end
  puts "  Total: #{rows.length} file(s) across #{by_root.keys.map(&:first).uniq.length} provider(s)"
end

# ── 3. Minio — intraday objects ───────────────────────────────────────────────

section "Minio — intraday_publisher uploads (bucket: tickrake-intraday)"

datastore = config.datastores["minio_intraday"]

unless datastore
  puts "  minio_intraday datastore is not configured — skipping"
  exit 0
end

endpoint = (datastore.endpoint || "").gsub("//minio:", "//localhost:")
s3 = Aws::S3::Client.new(
  region: datastore.region || "us-east-1",
  endpoint: endpoint,
  force_path_style: datastore.force_path_style,
  credentials: Aws::Credentials.new(datastore.access_key_id, datastore.secret_access_key)
)

begin
  resp = s3.list_objects_v2(bucket: datastore.bucket, prefix: "intraday/")
  objects = resp.contents

  if objects.empty?
    puts "  (none — intraday_publisher may not have run yet)"
  else
    csvs   = objects.select { |o| o.key.end_with?(".csv") }
    jsons  = objects.select { |o| o.key.end_with?(".json") }
    total_bytes = objects.sum(&:size)

    puts "  #{objects.length} object(s) total — #{csvs.length} CSV(s), #{jsons.length} JSON index(es)"
    puts "  Total size: #{(total_bytes / 1024.0).round(1)} KB"
    puts "  Last modified: #{objects.map(&:last_modified).max}"
    puts ""

    objects.sort_by(&:key).each do |obj|
      puts "  #{obj.key}  (#{obj.size} bytes, #{obj.last_modified.strftime('%H:%M:%S')})"
    end
  end
rescue Aws::S3::Errors::NoSuchBucket
  puts "  Bucket '#{datastore.bucket}' does not exist — run docker compose up minio_init"
rescue Aws::Errors::ServiceError => e
  puts "  Minio error: #{e.message}"
  puts "  Is the minio container running? (docker ps)"
end
