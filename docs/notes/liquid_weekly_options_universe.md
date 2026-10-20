---
status: research-candidates
as_of: 2026-10-17
tags: [options, universe, research]
---

# Candidate universe for liquid short-dated options

## Purpose

Build a broad research universe for collecting intraday option-chain
observations. This is a candidate list to investigate, not a claim that every
strike is liquid or a recommendation to trade. It is intentionally broader
than the vendor example file `orats_intraday_1min_tickers.json`:
that file is a vendor example, not the boundary of our universe.

Here, **multiple expirations per week** means listed expirations on multiple
weekdays, including the regular Friday weekly. A Friday-only weekly chain is
still useful, but it does not meet that stricter frequency by itself. Some
short-dated listings are exchange-specific, are limited to a few future dates,
skip earnings dates, and are reviewed quarterly.

## Candidate set

### Start with the broad, heavily traded index and ETF chains

These are the first products to cover because their aggregate options markets
are consistently among the largest and several have weekday expirations:

`SPY`, `QQQ`, `IWM`, `SPX`, `XSP`, `DIA`, `VIX`, `GLD`, `SLV`, `TLT`, `XLF`,
`SMH`, `XLE`, `GDX`, `TQQQ`, `LQD`, `IEF`, `DRAM`, `HYG`, `EEM`, `EFA`,
`ARKK`, `KRE`, `XBI`, `USO`, `UNG`, `VXX`, `UVXY`, `SQQQ`, `SOXL`, `BITO`,
`IBIT`.

The most established weekday-expiration set includes `SPY`, `QQQ`, and `IWM`
(Monday through Thursday in addition to Friday); `GLD`, `SLV`, and `TLT` have
Monday/Wednesday expirations; `USO` and `UNG` have Wednesday expirations.
`SPX`/`XSP` have multiple weekday expirations. Other weekday listings are
subject to the quarterly qualifying-security lists and exchange rules. BOX's
Q4 2026 list includes `GLD`, `IBIT`, `XLF`, `TLT`, `SLV`, `TQQQ`, `SMH`, `XLE`,
`GDX`, `LQD`, and `IEF` among qualifying ETFs.

### Add liquid single stocks with short-dated weekday listings

Pursue these as a broad core for Monday/Wednesday plus Friday coverage:

`AAPL`, `AMZN`, `AVGO`, `GOOG`, `GOOGL`, `META`, `MSFT`, `NVDA`, `TSLA`, `AMD`,
`MU`.

The first group (`AAPL`, `AMZN`, `AVGO`, `GOOG`/`GOOGL`, `META`, `MSFT`,
`NVDA`, `TSLA`) formed the initial qualifying-stock group. `AMD` and `MU` have
since appeared on qualifying lists; the active set can change by quarter and
exchange. The current BOX Q4 2026 list also includes `SPCX`; include it in
coverage discovery, but treat its liquidity as requiring independent
confirmation rather than assuming it matches the mega-cap names.

### Broader weekly stock candidates

These are additional names to screen for weekly eligibility and recurring
chain depth. This expansion bucket is intentionally broad and is not
prevalidated as liquid; keep a name only after its 20-trading-day activity and
actual near-the-money quotes have been checked:

`ADBE`, `ADSK`, `AFRM`, `AAL`, `BAC`, `BABA`, `BA`, `C`, `CAT`, `COIN`, `COST`,
`CRM`, `CVNA`, `DAL`, `DIS`, `F`, `GME`, `GS`, `HD`, `HOOD`, `IBM`, `INTC`,
`JPM`, `KO`, `LLY`, `MARA`, `MCD`, `MSTR`, `NFLX`, `NKE`, `ORCL`, `PFE`, `PLTR`,
`QCOM`, `RIVN`, `SHOP`, `SMCI`, `SOFI`, `TSM`, `UBER`, `WFC`, `WMT`.

This is a discovery bucket, not a uniform liquidity tier. Names such as `GME`,
`MARA`, `RIVN`, and `SMCI` can be event-driven and have less dependable depth
away from the most active strikes. `BAC`, `C`, `F`, `PFE`, and `WMT` may have
heavy aggregate volume while individual short-dated strikes remain uneven.

### Weekly ETF and index expansion candidates

For breadth beyond the largest ETF chains, screen:

`EEM`, `EFA`, `EWZ`, `FXI`, `GDXJ`, `HYG`, `KRE`, `LQD`, `OIH`, `PBR`, `XBI`,
`XLE`, `XLF`, `XLI`, `XLK`, `XLP`, `XLU`, `XLY`, `XOP`, `XRT`, `XSP`, `NDX`,
`OEX`, `XEO`, `DJX`.

Several overlap prior lists. Keep one canonical symbol universe and attach
expiration schedule/venue metadata rather than maintaining overlapping manual
lists.

## Liquidity validation before promoting a symbol

Treat the lists above as candidates. For each underlying, evaluate the option
chain by expiration and strike over a rolling sample (initially 20 trading
days):

1. Confirm that the product is currently listed and record which weekdays and
   venues have expirations. Do not infer this from the underlying having any
   options.
2. Measure options volume and open interest per expiration, with special
   attention to the nearest expirations and strikes near the forward/spot.
3. Measure quote availability, median bid/ask width as a fraction of midpoint,
   and quote staleness during regular trading hours. Exclude zero bids and
   crossed/locked quotes from width summaries.
4. Track how often a symbol has usable two-sided quotes across strikes and
   expirations, not just total underlying option volume. High aggregate volume
   can be concentrated in one event, one strike, or one expiration.
5. Keep an explicit status such as `candidate`, `validated`, or `inactive`,
   along with the observation window and the reason for promotion/removal.

An initial screening floor of 5,000 contracts average daily volume across all
expirations can be used to keep the discovery pass manageable, but it is only a
coarse threshold. The final decision should be based on short-dated chain
depth and quote quality; aggregate volume alone does not prove that every
weekly expiration is liquid.

## Evidence and freshness

- [Cboe Available Weeklys](https://www.cboe.com/available_weeklys/) publishes
  the currently available weekly products and expiration calendar. Listings
  change, so refresh this source before creating a production allowlist.
- [BOX's Q4 2026 qualifying-security notice](https://boxexchange.com/assets/Notice-2026-096-Short-Term-Option-Series-Qualifying-Securities-for-Q4-of-2026.pdf)
  is an example of the quarterly changes to additional short-dated listings.
- [Options volume report](https://marketchameleon.com/Reports/optionVolumeReport)
  provides a recent cross-sectional activity snapshot; use a rolling history
  rather than a single session to validate persistence.
- [A recent options-volume table](https://elixstocks.com/options) illustrates
  how much volume is concentrated in a relatively small set of names. It is a
  screen, not a contract-level liquidity measure.
- [A weekly-options liquidity screen](https://apexvol.com/best/weekly-options-stocks)
  uses 5,000 average daily contracts as an initial volume floor; this note
  treats that only as a coarse discovery threshold.

The candidate list is based on exchange schedules and recent market activity
available on 2026-10-17. Historical vendor universes can include delisted,
renamed, or otherwise inactive symbols; check current identity and listing
status before ingestion.
