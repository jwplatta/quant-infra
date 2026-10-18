require "tickrake"

Tickrake.job "historical_publisher" do
  schedule do
    # Interval between historical scan/sync passes
    every 60.seconds
  end

  historical_publish do
    datastore :minio_historical
    datasets :all # scans options, candles, level_one, order_book, fundamentals, economic_events
    retain_days 10 # Retain published local files for ten days (candles are exempt)
    # Optional: limit batch size per pass
    # batch_size 100
  end
end
