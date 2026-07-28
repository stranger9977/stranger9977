# Camp battles 2026 — what the data actually says

Depth-chart history from nflverse daily snapshots, 22 Mar – 27 Jul 2026.
Beat coverage from 28 team research agents. Rerun the pipeline with
`make` (see README) — every number below regenerates.

## The one idea

A depth chart is a time series, not a document. Most of its movement is
the transaction wire. Strip that out and what remains is the only thing
worth calling a camp battle.

## Headline numbers

| | |
|---|---|
| Depth-chart changes since 1 May | 1,077 |
| …that were actual competition | 806 (75%) |
| …that were arrivals or departures | 271 (25%) |
| Distinct contested slots | **586** |
| Fantasy-relevant | 54 |
| With beat/analyst coverage | 173 |
| Teams researched | 28 of 32 |

The 27% matters. It invalidated the first pass at team rankings, which
had Carolina, the Jets, Buffalo and the Giants near the top purely
because they were active in free agency. Those are transaction leaders,
not competitive rosters. Miami being "stripped for parts" rather than
genuinely competitive shows up exactly this way.

## What counts as a battle

For a change A → B at some slot on day D:

| A still on the team's chart on D? | B on the chart on D−1? | verdict |
|---|---|---|
| yes | yes | **competition** |
| no | — | departure (A left) |
| — | no | arrival (B joined) |

Only competition is a battle. Both men were already on the roster and one
passed the other. This is what separates a real fight from Jared Verse
being traded to Cleveland and appearing next to Myles Garrett.

## Three buckets, and only two are trustworthy

Crossing 586 computed battles against 140 reported ones:

- **BOTH — 173.** Data and media agree. Validated.
- **DATA ONLY — 313.** The chart keeps moving and nobody wrote a word.
- **MEDIA ONLY — 68.** Covered, chart never moved.

**Do not read MEDIA ONLY as "manufactured."** Sorted by side of the ball:

| side | reported | never registers | |
|---|---|---|---|
| defense | 44 | 28 | **64%** |
| other | 43 | 22 | 51% |
| offense-skill | 21 | 10 | 48% |
| o-line | 32 | 8 | **25%** |

That gradient is chart resolution, not media behaviour. A public depth
chart lists DE, DT, LB, CB, S. It has no row for the nickel, no row for
the third safety, no row for a rotational edge. A fight can be entirely
real and have nowhere to appear.

So the defensible claim runs one direction only: **there are real
competitions nobody is covering.** The reverse needs a source that can
see defensive sub-packages, which a public depth chart cannot.

## Validated fantasy battles worth a segment

- **ATL QB1 — Tua Tagovailoa over Michael Penix Jr.** The strongest
  finding in the file. It surfaces independently in the drift model and
  in the beat coverage. New regime (Stefanski/Cunningham) with no
  attachment to Penix, who is rehabbing an ACL; Tua signed for ~$1.3M
  because Miami still owes him $54M guaranteed. Neither man is protected
  by money, which is why it is real.
- **JAX RB1 — Bhayshul Tuten vs Chris Rodriguez Jr.** Early-down lead
  back, unresolved.
- **HOU WR3 — Jaylin Noel past Tank Dell.** Noel WR5 → WR3 over six weeks.
- **TB WR1 — Emeka Egbuka past Chris Godwin.**
- **DAL TE2 — Brevyn Spann-Ford over Luke Schoonmaker.**
- **IND kicker — Blake Grupe / Spencer Shrader.** Kickers are the purest
  camp battle: one job, no ambiguity, decided on merit.

## Uncovered and moving — where the original reporting is

The sharpest editorial position available. These slots keep changing
hands and no beat writer or fantasy analyst has touched them:

- **GB RB2/RB3 — MarShawn Lloyd vs Chris Brooks.**
- **BUF RB2/RB3 — Ray Davis vs Ty Johnson.**
- **CAR TE1/TE2 — Tommy Tremble vs Ja'Tavion Sanders.**
- **ATL KR1/PR1 — Zachariah Branch over Deven Thompkins.** Both return
  jobs, same two men.
- **MIN WR5, NE WR2/WR3, LAC RB2, MIN RB3.**

## Rookies

- 224 of 257 picks matched to a depth-chart slot.
- 29 rookies hold a rank-1 slot.
- 14 of those are first-round picks, and **every one has move = 0** —
  they were installed as starters in March and have not moved since.
  Draft capital is destiny at the top of the chart.
- All actual movement is round 3 and below. Kaden Wetjen (R4) went
  KR5 → KR1; Zavion Thomas (R3) went KR4 → KR1.

## Method traps that cost real time

Each of these failed silently — nothing raised, the numbers were just
wrong.

1. **Never identify players by name — not across rows, not across days.**
   Two distinct failures, both silent:

   *Collisions.* Two DeVonta Smiths on 2026 rosters (Eagles WR, rookie
   Carolina DB) made a five-year veteran appear as a climbing rookie. Six
   such collisions this season.

   *Renames.* The chart rewrites the same player between snapshots —
   suffixes appear (`Dion Wilson` → `Dion Wilson Jr.`), punctuation drops
   (`T.J. Parker` → `TJ Parker`), nicknames formalise (`Cam Ross` →
   `Cameron Ross`, `JT Tuimoloau` → `Jaylahn Tuimoloau`, `Jalen Cropper` →
   `Jalen Moreno-Cropper`). Compared as strings, each of those is one
   player leaving and another arriving: **29 phantom transactions**, which
   inflated the transaction leaderboard by ~10%. Both `battles.py` and
   `drift.py` now key on `gsis_id` and carry names for display only.

   Battle counts did not move — renames were classified as departures, so
   they were already excluded from competition. The damage was confined to
   the transaction wire and to `drift.py`, where a rename would have
   surfaced as a player dropping off the chart and a stranger appearing.
2. **`draft_picks.gsis_id` does not hold gsis ids.** It holds PFR-format
   ids (`LOV121782`) while rosters use gsis (`00-0023459`). Merging the
   two matches nothing and every rookie returns UDFA. Join on `pfr_id`
   with a name+team fallback.
3. **Parquet does not reliably round-trip object columns.** A list column
   built via `groupby().apply(lambda d: pd.Series({...}))` comes back as
   the string `'["A","B"]'`, which iterates as *characters*. The name
   join silently matched zero. Build column-wise, and parse defensively
   on read (`battles.as_list`).
4. **Aggregating only the winner loses the loser.** A slot that flipped
   once reported one name, which reads as nobody having competed for it.
   Fixing this alone moved 30 slots from uncovered to validated.
5. **Swaps double-count.** Ray Davis and Ty Johnson trading RB2 and RB3
   produced two rows that disagreed about who won. Group by contender set.
6. **Do not z-score against a distribution that is 97% zeros.** The
   near-zero std makes every move score ±10, so z becomes a monotone
   restatement of raw rank change and hands the leaderboard to whichever
   receiver shuffled between 9th and 12th. Condition on having moved.
7. **A failed research agent is not a settled roster.** The agent pool
   exhausted its WebSearch budget mid-run; the remaining agents correctly
   returned zero battles rather than inventing coverage. Recorded as-is,
   those empties are indistinguishable from a quiet team and every slot
   scores as "nobody is covering this" when the truth is nobody looked.
   `harvest.py` drops them.

## Still open

- **Ourlads and Rotowire are unscraped.** Both hosts are blocked by the
  sandbox egress policy (403 on CONNECT), so there is one source and
  cross-source disagreement is structurally zero. BeautifulSoup does not
  help — it is a parser, not a fetcher; the block is at the network
  layer. The scrapers in `sources.py` are written but untested and need
  to run on a machine with open egress.
- **Source-accuracy scorecard** needs those scrapers plus a decision on
  the answer key: official pre-Week-1 depth charts, or Week 1 actual
  starters.
- **Headshots** are blocked the same way (`static.www.nfl.com`).
