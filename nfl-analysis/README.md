# NFL Non-Obvious Insights

Five charts (plus two bonus) produced by an automated research loop over the
nflverse/nflfastR data universe: brainstorm hypotheses → web-search whether the
idea is already published (reject known ones) → test in R with rigor checks →
adversarial chart review. Data: play-by-play 2015–2024, FTN charting 2022–2024,
NGS participation/coverage 2016–2023, Next Gen Stats, weekly player stats,
draft picks.

Reproduce: download data per `scripts/prep_data.R` comments, run
`Rscript scripts/prep_data.R`, then any `Rscript scripts/<slug>.R`.

---

## Round 2 — Directed deep dives (timeouts, icing, sequencing, predictability)

Four commissioned tracks, each with a coach/play-caller leaderboard through the
**2025 season**. Play callers attributed from the samhoppen/NFL_public dataset
(offensive + defensive play caller per team-game 1999–2025); coach timeout
decisions from `games.csv` head coaches.

### T1. Timeout discipline — "The two ways to waste a timeout"
(`charts/timeout_discipline.png`) — 2000–2025, 14,030 team-games. Two distinct
sins: **burning them early** (delay-of-game bailouts before the last 4:00) —
Mike Martz is the runaway worst at +1.02/game over his era, double the league in
all six seasons; current burners are Jim Harbaugh, LaFleur, McVay, Payton — and
**dying with them late** (one-score Q4 losses ending with a timeout unused) —
Norv Turner 35% (11/31, p=0.003) vs the 15% league rate; Gary Kubiak 0/26.
Twists: Mike Shanahan is the only coach in the worst-8 of *both*; Andy Reid, the
most-mocked clock manager alive, almost never dies with timeouts (4/61, best
large-sample rate).

### T2. Icing the kicker — "Shaves ~3 pts off makes, but 26 seasons can't prove it"
(`charts/icing-the-kicker.png`, `charts/icing-coach-funnel.png`) — 2,221 pressure
FGs; controlled inside the 1,782 where the defense had a timeout to spend. After
controlling for distance, EB kicker quality, weather, era, and situation, icing's
effect is **−2.9 pts of make probability, 95% CI [−7.0, +1.2]** — suggestive but
statistically indistinguishable from nothing. Heaviest icer: Matt LaFleur (67%);
the funnel shows **20 of 21 coaches' icing effects sit inside the pure-luck
cone** — nobody owns the ice.

### T3. Play sequencing — the equilibrium map & the death of "establish the run"
(`charts/equilibrium_map.png`, `charts/sequencing_death.png`) — 2015–2025. The
pass-minus-run EPA gap runs from **+0.22** (late & close, 1st down; league passes
63%) to **−0.50** at 4th-&-1 and **−0.21** on goal-to-go 3rd down (league passes
68% — the mix flips inside the 5). And "establish the run" is a myth: a pass after
a prior run gains −0.015 EPA vs after a pass on 1st-and-10 — every game-state cell
sits inside the negligible band. (Self-selected cells drawn as hollow points.)

### T4. Play-caller predictability — "The best play-callers are more predictable"
(`charts/predictability_vs_epa_scatter.png`, `charts/predictability_leaderboard.png`)
— 305,827 called plays, conditional-entropy predictability with empirical-Bayes
de-biasing. The "elite coaches are unpredictable" trope is a game-script illusion:
raw entropy says unpredictable=good (r=+0.33), but that's because good offenses
live in balanced down-and-distance. Controlling for situation, **the sign flips —
more predictable callers run better offenses (r=−0.37)**. Andy Reid is the poster
child: a situational guesser gets ~3.1 more calls right per 100 against him than
against an average caller, and he runs the league's best offense. Unpredictability
is mostly a symptom of bad callers; Ben Johnson is the lone hard-to-read elite.

---

## Round 1 — The five

### 1. Offense — Motion barely taxes man coverage (`charts/motion-man-tax.png`)
Over 31,468 charted dropbacks (2022–23), pre-snap motion's celebrated
"man-coverage tax" is statistically nothing: the motion-vs-man diff-in-diff is
+0.03 EPA/play (95% CI −0.04 to +0.11). And the deterrence story is flatly
false — defenses call man 35.4% without motion and 35.8% with it. Several
defenses (DAL, ATL, CLE, BAL) call *more* man against motion and pay no EPA
bill for it.

### 2. Special teams — Coaches aren't wind-blind (`charts/wind_savvy_coaches.png`)
On outdoor 4th downs with a 48–58 yard field goal available, attempt rates fall
from 50% in calm air to 34% at 11–15 mph (p < 0.001) — while the make rate on
kicks actually attempted stays flat (~69% → 62–67%, p = 0.16). Coaches price
wind into the decision before it can show up in outcomes; the exploitable
"wind-blind coach" error doesn't exist.

### 3. Game management — The burned timeout costs a tenth of a point
(`charts/burned_timeout_price.png`)
Q2 drives starting inside 2:00 score 0.88 points with 0 timeouts vs 1.58 with
3 — but 3-timeout offenses also get the ball ~21 seconds earlier. Holding start
clock, field position, score, and pregame Vegas win probability fixed, the gap
shrinks to +0.24 points (p = 0.18): ~0.08 points per banked timeout, an order
of magnitude below the conventional-wisdom price of a wasted timeout.

### 4. Roster/talent — Draft pedigree goes stale by Week 4
(`charts/pedigree-half-life.png`)
For rookie WRs (2011–2022, n = 162), draft slot dominates prediction of
years-2/3 production only on opening day; by week 4 cumulative target share
overtakes it, and by week 8 slot uniquely explains ~1% vs ~14% for usage. The
sharpest wrinkle: target share earned while the team's WR1 was healthy carries
the whole signal (β = 0.59, p = 0.005); injury-inflated share with the WR1 out
predicts nothing (p = 0.46). Forced usage is a false positive — earned usage is
the talent read.

### 5. Defense — Defenses blitz on autopilot (`charts/blitz-autopilot.png`)
Pressure is pressure: when it arrives, EPA allowed is the same blitzed or not
(−0.31 vs −0.29), but a failed blitz costs more than a failed 4-man rush
(+0.30 vs +0.22). So the blitz only pays if its ~12-point pressure bump clears
a QB-specific break-even — which two-thirds of QBs do (blitzing Josh Allen pays
at any pressure rate; against Kyler, Tua, Burrow, Purdy, Prescott it never
does). Yet coordinators' actual blitz rates are uncorrelated with this payoff
(r = 0.06, p = 0.71).

## Bonus (also passed review after the quota filled)

- **Zone gives up the catch, man gives up the down**
  (`charts/zone-catch-man-sticks.png`) — on 3rd & 11+, zone allows 17 points
  more completions but 7 points *fewer* conversions than man: the stat everyone
  quotes and the stat that decides possessions rank the coverages in opposite
  directions.
- **The rational foul** (`charts/rational-foul-dpi.png`) — on 35+ yard throws a
  spot-foul DPI costs the defense 0.79 EPA less than the completion, because
  the foul deletes YAC and the touchdown (34% of 35+ yd catches score).

Methods, samples, and robustness checks are documented in each script and on
each chart's caption.
