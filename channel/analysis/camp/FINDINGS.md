# Camp battles — data findings

Scaffold, not prose. Numbers, caveats, and candidate angles. You write.

Run `churn.py` to reproduce. Data: nflreadr/ESPN timestamped depth charts.

---

## 1. The data (better than expected)

`nfl_data_py.import_depth_charts()` returns **daily timestamped snapshots**, not a
static chart. Two files tile a full annual cycle:

| File | Coverage | Snapshots |
|---|---|---|
| 2025 | 3 Aug 2025 → 14 Mar 2026 | 219 |
| 2026 | 22 Mar 2026 → **27 Jul 2026 (today)** | 127 |

Pre-2025 uses a different schema with no `dt` column, so **two seasons is all the
history there is.** That's a real limitation on any claim about typical years.

881 starting slots league-wide (32 teams × ~27 position slots). A "change" = the rank-1
player at a slot differs from the previous day's snapshot.

Also available and not yet used: `import_contracts`, `import_draft_picks`,
`import_snap_counts`, `import_injuries`, `import_weekly_rosters`.

## 2. The finding

**Starter changes by month, league-wide:**

```
Aug 2025    213  ####################################
Sep 2025    183  ##############################
Oct 2025    185  ###############################
Nov 2025    187  ###############################
Dec 2025    187  ###############################
Jan 2026     62  ##########
Feb 2026    155  ##########################
Mar 2026    489  ##################################################################################
Apr 2026     65  ###########
May 2026     41  #######
Jun 2026     30  #####
Jul 2026     13  ##
```

**March: 489. July: 13.** Roughly 37× more roster movement in free agency month than in
the month everyone publishes camp-battle content.

Weekly peaks line up exactly with the calendar's real decision points:

| Week | Changes | What |
|---|---|---|
| 15 Mar 2026 | **293** | free agency opens |
| 15 Feb 2026 | 143 | franchise tag window |
| 31 Aug 2025 | 79 | 53-man cutdown |
| in-season | 30–60/wk | injuries, benchings |
| **26 Jul 2026** | **5** | **camp opens** |

**Frozen slots:**
- Since 1 May: 75 of 881 slots moved — **91.5% unchanged**
- Since 1 Jun: 40 of 881 moved — **95.5% unchanged**
- 52% of all offseason churn happened at or before the draft

## 3. What *is* unsettled

Post-draft movement, by position — and it is not where the coverage is:

```
KR   7      LG   5
LT   7      PK   5
NB   7      SLB  5
RCB  6      WLB  5
RG   6      RDE  4
PR   6      QB   3   (only 3 league-wide)
```

**Kick returner, punt returner, nickel back, kicker, guard.** The lowest-salience jobs on
the roster. Meanwhile QB moved three times all offseason across 32 teams.

**Most unstable teams** (total starter changes, whole offseason):

| | | | |
|---|---|---|---|
| MIA 20 | NYJ 17 | NYG 14 | MIN 12 |
| PIT 12 | TB 10 | ATL 9 | BAL 8 |

**Most settled:** DEN **0**, CIN 1, BUF 2, SEA 2, SF 2, CAR 2.

Denver did not change a single starting slot in four months.

## 4. Caveats — read before writing anything

1. **This measures ESPN's depth chart, not the team's.** Teams don't publish real ones
   until late August. What's being measured is *the informed outside view changing its
   mind.* Arguably that's the more interesting quantity — but say so, don't hide it.
2. **Two seasons of data.** No claim about "typical" offseasons is supported. One weird
   year and the shape changes.
3. **No July 2025 baseline.** The 2025 file starts 3 Aug, so July-to-July is impossible.
   Cannot yet fully separate *"rosters are settled"* from *"the chart goes stale in
   summer."*
4. **Partial mitigation:** the instrument is demonstrably responsive — 79 changes in
   cutdown week, 30–60/week all season. It is not a dead feed. But responsive-in-season
   doesn't prove responsive-in-July.
5. The Aug 2025 number (213) is inflated by the series starting 3 Aug; first-observation
   effects. Don't quote it as a clean monthly figure.

**The honest version of the claim:** *by the one continuously-updated public depth chart,
July is the quietest month of the NFL year.* Not "rosters are settled" — that's a claim
the data can't yet carry.

## 5. Candidate angles

**A. The dead month.** *Camp battle season is the deadest month of the NFL calendar. The
roster was decided in March.* Strongest, most falsifiable, best chart. Risk: caveat 3.

**B. The jobs nobody covers.** *The spots that are genuinely open are kick returner,
nickel back and right guard. Nobody writes a camp battle story about the returner.*
Reversal: the coverage is inversely correlated with the actual uncertainty. Needs the
agent data to confirm what's actually being covered.

**C. Denver.** *One team hasn't changed a single starter in four months.* Small, human,
very shareable. Probably a short, not a feature.

**D. The instrument piece.** *What a depth chart actually is, and why nobody should trust
one in July.* This is the mechanism angle — see `animate/references/mechanism.md`.
Evergreen, and it makes the caveat the subject rather than a footnote.

My read: **A is the feature, B is the turn inside it, C is the short.** D is a strong
separate evergreen piece.

## 6. Still needed

- [ ] **The multi-source cross you actually asked for.** Ourlads + Rotowire vs ESPN.
      Between-source *disagreement* is a different signal from within-source *churn*, and
      having both is stronger than either. Neither is in `nfl_data_py`; both need scraping.
- [ ] **Contract cross.** `import_contracts` → does guaranteed money predict which slots
      never move? If yes, that's the "the money already decided it" reversal, quantified.
- [ ] **32 team agents** — running now, will give the coverage side of angle B.
- [ ] A July 2025 baseline from some archived source, to close caveat 3.
