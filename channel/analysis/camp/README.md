# Camp battle tracker

Three reads on who is starting, tracked daily. The point of three sources is
**disagreement**, not redundancy — where they agree the job is settled, where
they diverge somebody is guessing.

## Two different signals

| | Measures | Needs |
|---|---|---|
| **Movement** | one source changing its mind over time | 2+ days |
| **Disagreement** | sources contradicting each other right now | 2+ sources |

A slot that is **both** is the strongest camp-battle signal available without a
beat reporter.

## Daily loop

```bash
python track.py --seed        # ONE TIME: backfill espn from nflverse (127 days)
python track.py               # daily: snapshot all sources, append, report
python track.py --no-scrape   # espn only — works anywhere
python track.py --report      # read existing history, capture nothing
python build_artifact.py      # regenerate undercard.html
```

Idempotent — re-running on the same day replaces that day rather than
duplicating, so it is safe to schedule.

## Source status

| Source | Status | Notes |
|---|---|---|
| **espn** (via nflverse) | **working** | Daily timestamped, archived to 22 Mar 2026. Seedable. |
| **ourlads** | untested | Scraper written from published page structure, not a live response. Blocked by egress in the dev sandbox. Expect one pass of selector fixing. |
| **rotowire** | untested | Same. Selectors are the fragile part. |

Neither Ourlads nor Rotowire has a public archive, which is exactly why they
have to be captured going forward — every day not captured is gone.

## Headshots

`headshots.py` pulls `headshot_url` from nflverse rosters, square-crops to 96px,
and writes base64 data URIs to `headshots.json`.

Inlining is **mandatory**, not a preference: published artifacts run under a CSP
that blocks every external host, so a remote `<img src>` fails silently. Keep the
cache under ~3 MB or the artifact will not load.

## What the data cannot do

- **No July 2025 baseline.** nflverse depth charts only carry the timestamped
  schema for 2025 (from 3 Aug) and 2026 (from 22 Mar). A same-window
  year-over-year comparison for July is not possible from this source.
- **This is ESPN's chart, not any team's.** Teams do not publish real depth
  charts until late August. What is measured is the informed outside view
  changing its mind.

## Files

```
sources.py        three loaders -> one schema
track.py          snapshot, history, movement, disagreement
headshots.py      fetch + inline as data URIs
churn.py          the original annual-cycle analysis
build_artifact.py inject data into undercard.tpl.html
FINDINGS.md       numbers, angles, caveats
```
