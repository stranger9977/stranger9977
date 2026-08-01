# The angle: college football rebuilds became an options trade

Every number below regenerates from `python rebuild.py` — public mirrors,
no API key, verified in-sandbox on 2015–2025 rosters and schedules.

## The claim, in one paragraph

Flipping your roster does not make you better on average. It makes you
**more volatile** — and in a sport whose payoff went winner-take-all
(12-team playoff money, portal-fed attention cycles), volatility is now
worth paying for. Before 2021, rosters were held together by *rules*:
transfer and sit a year. NIL and the portal repealed that, so retention
went from free to purchased — and the price of tearing a roster down
collapsed. That one repricing explains both things you noticed: why the
sport feels unrecognizable in five years, and why the coaching carousel
just set records. **Firing a coach used to mean writing off a
four-recruiting-class asset. Now a roster is one December of payroll.
ADs aren't impatient — they're buying vol.**

## The three numbers that carry it

**1. The median FBS team now returns barely half its roster.**

| season | median retention |
|---|---|
| 2019 | 73.5% |
| 2021 | 69.4% |
| 2022 | **56.9%** |
| 2025 | **52.0%** |

The cliff is exactly 2021→2022: first season after the one-time free
transfer (April 2021) and NIL (July 2021). Not a drift — a step.

**2. The tail flipped sides — this is the finding.**

Teams coming off a ≤4-win season, split by what they did with the roster:

| | mean improvement | reached 9+ wins |
|---|---|---|
| **before (2016–19)** — kept roster | +2.14 | **14.3%** |
| before — flipped roster | +1.51 | 7.0% |
| **portal era (2022+)** — kept roster | +2.45 | 7.1% |
| portal era — flipped roster | +1.81 | **14.3%** |

Keeping your players still wins **on average**, in both eras. What
changed is the *ceiling*. Before, a mass-exodus roster was a symptom —
those teams stayed bad. Now it's a strategy, and it's the one that
produces the breakout seasons. The mean stayed put; the variance moved.
Continuity buys a floor. The ceiling is bought in the portal.

That's an options trade. A 6-win floor is worth almost nothing in the
current payoff structure; a 15% shot at a playoff season is worth a
great deal. So rational programs pay to run high-variance rebuilds —
and the cleanest way to start one is a new head coach.

**3. Every 2025 breakout flipped.**

All ten of the biggest 2025 win-jumps kept ≤52% of the prior roster:
Kennesaw State 2→10 (kept 34%), Houston 4→10 (47%), North Texas 6→12
(36%), Southern Miss 1→7 (**kept 20%** — Charles Huff arrived and
brought Marshall with him), Utah 5→11 (40%), Virginia 5→11 (52%).
Earlier cases: Colorado 2023 kept **22%** of the roster; Indiana 2024
(47%) went 3→11 under a first-year coach; Arizona State (51%) 3→11.
And UNC 2025 under Belichick kept 31%.

Supporting: 5+ win swings are up ~30% (10.1% → 13.3% of team-seasons),
and the winners' premium is new — in 2018 top-25 teams retained exactly
the league median (73% vs 73%); in 2025 they out-retain the field
(57% vs 50%). Retention used to be free. Now it's a line item, and the
rich buy more of it.

## Why this is the genuinely interesting version

Everyone's NIL take is either "chaos, tradition is dead" or "players
finally getting paid." Both are moral takes. This is a **market
mechanics** take nobody makes because it needs the data and a pricing
instinct: the rules change didn't make teams better or worse, it changed
*what risk costs*. Roster flips are volatility purchases. Coaching
changes are how you initiate one. The carousel isn't a panic — it's the
market clearing at the new price of starting over.

It also explains the thing the moral takes can't: why the blue bloods
fired coaches mid-season (LSU, Penn State) in the same cycle that
Indiana — Indiana — made a playoff off a roster flip. Both are the same
trade from opposite ends.

## What I could not verify from this sandbox — check before publishing

- **Carousel count.** The 2025–26 cycle (Penn State, LSU, Florida,
  Auburn mid-season firings and after) is record-scale by my knowledge,
  but I could not pull a coach dataset here (ESPN API and CFBD both
  blocked). CFBD's `/coaches` endpoint has it: verify the count and the
  mid-season-firing count against prior cycles.
- **Buyout figures** for the "the only remaining cost of firing is the
  buyout" beat (Kelly's and Franklin's are public reporting).
- The tercile cells are n≈42 with ~6 hits each — directionally strong
  and corroborated by the case list, but quote the case list, not a
  p-value.
- 2025's retention low is partly the House-settlement 105-man roster
  purge. The 2022 cliff is the clean evidence; 2025 extends it with an
  asterisk.

## Honest confounds, already handled

- **ESPN coverage break in 2019** (rosters 93→114 as walk-ons appear):
  all headline numbers start at 2019. The cliff sits inside the stable
  window.
- **COVID eligibility bubble**: would predict turnover *fading* by
  2024–25 as super-seniors age out. Retention is still falling. The
  bubble can't explain the step in 2022 either.
- **Class-of-departure data is unusable** in this source (inconsistent
  coding) — nothing here relies on it.

## The piece this becomes

- **Title direction:** "College football fired everyone. The math says
  they were right." / "Rebuilding is dead. This is what replaced it." /
  "Indiana and LSU made the same trade."
- **Spine chart:** the retention line 2019–2025 with three annotations
  (free transfer, NIL, roster caps). One line, one cliff. Manim-able in
  the house style.
- **The reveal beat:** the 2×2 table above, presented as "keeping your
  roster still works — watch what happens to the *ceiling*."
- **Case cast:** Southern Miss/Huff (the 20% roster), Indiana/Cignetti
  ("I win. Google me."), Colorado/Deion (the 22% original), LSU + Penn
  State (the sell side of the same trade).
- **Your edge on camera:** this is literally your day job — pricing
  variance. Nobody else in the space frames a roster flip as buying
  convexity, because nobody else prices things for a living.
- **Series hook:** the portal windows (December, April) are recurring
  tracker moments, same daily-loop mechanics as the camp tracker but
  pointed at a market instead of a depth chart.

## Data on your machine that upgrades it

- **CFBD API** (free key): coaches by season → compute time-to-first-
  winning-season by hire cohort; transfer portal entries → retention
  split into "left for another FBS roster" vs "gone from football,"
  which sharpens the 2025 asterisk.
- **On3 roster valuations**: does reported NIL spend predict which
  flips hit? (The "does the bag win" segment drops out of this angle
  for free.)
- **990s / FOIA aggregates**: the dollar layer, for the "retention
  became a line item" beat.
