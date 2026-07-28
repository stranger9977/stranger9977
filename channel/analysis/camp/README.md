# Camp battle tracker

Which NFL jobs are genuinely open, and which of those nobody is covering.
Numbers and angles live in `FINDINGS-camp.md`; the artifact is
`undercard2.html`.

## Run it

```bash
python track.py --seed          # ONCE: backfill espn history from nflverse
python track.py                 # daily: snapshot all sources, append
python battles.py               # competition vs transaction -> true_battles.parquet
python drift.py --weeks 6       # week-over-week movement    -> drift.parquet
python harvest.py               # collect team research      -> reported.json
python crossref.py              # computed vs reported       -> crossref.parquet
python payload.py               # assemble                   -> camp.json
python build_undercard.py       # inline into the artifact   -> undercard2.html
```

Idempotent — re-running on the same day replaces that day rather than
duplicating, so it is safe to schedule.

## The three signals, and they are not the same thing

| | Measures | Needs |
|---|---|---|
| **Movement** | one source changing its mind over time | 2+ days |
| **Disagreement** | sources contradicting each other right now | 2+ sources |
| **Coverage** | whether anyone wrote about it | the research agents |

A slot that moves *and* is uncovered is the sharpest thing available: a
story that demonstrably exists and has not been told.

## Files

| file | job |
|---|---|
| `sources.py` | three depth-chart loaders into one schema |
| `track.py` | snapshot, history, movement, disagreement |
| `battles.py` | separates competition from the transaction wire. The core idea |
| `drift.py` | rank change over a window, z-scored within position |
| `rookies.py` | rookie chart position against draft capital |
| `harvest.py` | pulls team research out of the workflow agent transcripts |
| `crossref.py` | joins computed battles to reported ones, on player names |
| `payload.py` | one JSON for the artifact |
| `build_undercard.py` | inline it into `undercard2.tpl.html` |
| `headshots.py` | fetch + inline player photos. **Untested** — host blocked |
| `churn.py`, `build_artifact.py` | the original annual-cycle analysis |

## Three things to know before trusting a number

**MEDIA ONLY is not "manufactured."** A battle can be entirely real and
still never touch the depth chart, because the chart has no row for it —
no nickel, no third safety, no rotational edge.
`crossref.resolution_check()` measures exactly this: 64% of covered
defensive battles never register, against 25% of o-line battles. That
gradient is chart resolution. Quote the DATA ONLY direction only.

**A team missing from `reported.json` is not a settled team.** It means
research failed. `harvest.py` drops zero-battle agents for that reason,
and the artifact greys those teams out rather than scoring them.

**This is ESPN's chart, not any team's.** Teams do not publish real depth
charts until late August. What is measured is the informed outside view
changing its mind.

## Blocked here, works elsewhere

`www.ourlads.com`, `www.rotowire.com` and `static.www.nfl.com` are refused
by this sandbox's egress policy (403 on CONNECT). That is a network-layer
block — BeautifulSoup does not help, it is a parser and not a fetcher. The
scrapers and the headshot fetcher are written and need a machine with open
egress.

Until they run there is one source, so `spread` is 0 everywhere and
cross-source disagreement is structurally unavailable. `history.parquet`
is already keyed on `source`, so those rows drop straight in. Neither
Ourlads nor Rotowire has a public archive — every day not captured is
gone, which is exactly why they have to be captured going forward.

Headshot inlining is **mandatory**, not a preference: published artifacts
run under a CSP that blocks every external host, so a remote `<img src>`
fails silently. Keep the cache under ~3 MB or the artifact will not load.

## What the data cannot do

**No July 2025 baseline.** nflverse depth charts only carry the timestamped
schema for 2025 (from 3 Aug) and 2026 (from 22 Mar), so a same-window
year-over-year comparison for July is not possible from this source. That
means we cannot yet separate "rosters are genuinely settled in July" from
"the chart just goes quiet in summer."
