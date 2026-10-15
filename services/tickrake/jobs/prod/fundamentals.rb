require "tickrake"

Tickrake.job "fundamentals" do
  provider :schwab
  universe "fundamentals_symbols"

  schedule do
    at "15:00"
    weekdays
  end

  fundamentals do
    batch_size 50
  end
end
