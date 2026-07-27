# The First 30 Days

Written for a start in **late July 2026**, which is close to ideal timing. US sports ad
rates bottom out from late June through August — post-NBA Finals, pre-NFL — so you're
sitting in the dead zone. That's the right time to **build a library, not launch into
silence.** NFL training camps open now, college football starts late August, Week 1 is
early September.

Target: go into Week 1 with four or five pieces already live.

---

## The organizing idea: chase the argument, not the news

This is the single most useful tactical finding from the research, and it resolves the
tension you were worried about.

A sports news video captures most of its lifetime views in the **first 48–72 hours**, and
the search spike starts decaying within hours. To catch a wave you'd need to publish
within 6–12 hours. **A 12-minute researched essay with custom charts cannot be produced in
six hours.** Newsjacking and your format are structurally incompatible, and pretending
otherwise produces videos that are both late *and* worse than your baseline.

But sports discourse isn't 300 unique topics a year. It's about **twenty arguments that
recycle endlessly**: is he a system quarterback, does the portal ruin continuity, is
analytics ruining football, does defense win championships, can he win the big one.

So: **pre-build the analysis for the recurring arguments.** When the discourse spikes, you
already have the model and the charts. You publish a *durable* essay that happens to land
in the moment, and it keeps earning search traffic for years after the moment dies.

That's the seam between newsjacking and evergreen, and a data-journalism channel is
uniquely able to occupy it, because nobody else has the model already built.

**Mix for a channel at zero: 70–80% evergreen, 20–30% topical.** Not just for production
reasons — Browse and Suggested traffic require an existing audience, Search doesn't. A new
channel has no browse surface to ride, so news videos underperform badly at your stage
while evergreen search-anchored essays compound from nothing.

---

## What 30 days realistically produces

Be honest about the arithmetic. At one hour a day, that's roughly 30 hours. A 12-minute
chart-driven explainer is 13–26 hours for the first few. So 30 days produces:

- **2 videos published** (the two you already have near-ready — that's the whole point of
  starting from them)
- **1 new video fully built**
- **The two reusable assets** that collapse all future production time
- **5 articles finished and cross-linked**
- **The idea bank below, validated and banked**

That is a genuinely good month. Anyone promising you 30 videos in 30 days is selling
something.

**And take the cadence advice seriously: start at 6–8 minutes, not 12.** You need reps
more than runtime. See `01-voice.md` §7.

---

## Week-by-week

### Week 1 — Ship what exists, build the machine

The two near-ready videos go out. Nothing new gets started.

| Day | 1 hour |
|---|---|
| 1 | Finish the five articles: masthead, cross-links, CTA footer. See `03-artifact-finishing.md`. |
| 2 | Video 1 final pass. Audio to −14 LUFS, thumbnail, title, description, chapters. |
| 3 | **Publish video 1.** Set up the email list. Link it everywhere. |
| 4 | Build `theme_againstthebook()` — the reusable ggplot theme. |
| 5 | Finish the ggplot theme. 24pt+ text, tabular numerals, `nflplotR` logos, 2560×1440 output. |
| 6 | Build the DaVinci Resolve project template: title cards, lower thirds, chart reveals, audio chain. |
| 7 | Finish the Resolve template. **Publish video 2.** |

The two assets built on days 4–7 are what take a video from 20 hours to 8. Building them
is worth more than a third video.

### Week 2 — First new piece, start to finish

Run the full pipeline once, deliberately, to find where it breaks.

| Day | 1 hour |
|---|---|
| 8 | `daily-topic` → `validate-idea`. **Lock the title and thumbnail before any analysis.** |
| 9–10 | Analysis in R. Charts through the new theme. |
| 11 | `write-article` → draft. |
| 12 | `write-script` → 6–8 minute script. Read it aloud. |
| 13 | Record VO. Retakes. Adobe Enhance. |
| 14 | Edit in the Resolve template. |

### Week 3 — Publish, instrument, bank ideas

| Day | 1 hour |
|---|---|
| 15 | Thumbnail, packaging, **publish video 3**. |
| 16 | Instrument: CTR, AVD, retention graph shape. Note where people leave. |
| 17–19 | Bank analysis for three recurring arguments from the list below. Don't write, just build models and charts. |
| 20 | Publish an article-only piece to keep the series alive between videos. |
| 21 | Review the retention graph on video 3 against the script. Which beat lost them? |

### Week 4 — Second cycle, faster

Same shape as week 2, but you now have the theme, the template, and one retention graph
of real feedback. Target: same output in noticeably fewer hours.

By day 30 you should have 3 videos live, 5 articles live, an email list running, two
reusable production assets, and banked analysis for three more pieces.

---

## The idea bank — 30 validated concepts

Every one of these is a **belief on trial** with a plausible reversal. That's the filter
from `channel/style/house-style.md`: if there's no reversal, it's a stats post, not a
piece.

Titles are two words where possible, following the series convention. Thumbnail concepts
lean on the format's real advantage: **a visibly strange chart is the faceless equivalent
of a shocked face.** Zero, one, or two words of text, huge. Never repeat the title.

### Tier 1 — Publish first (evergreen, high search, you can build these now)

| # | Title | Belief on trial | Possible reversal | Thumbnail |
|---|---|---|---|---|
| 1 | **The Portal** | The transfer portal is destroying college football. | Roster churn was always high; the portal made it *visible* and *legal*, not new. | Two roster-turnover curves, pre- and post-portal, closer than anyone expects |
| 2 | **Buy Low** | NIL money buys wins. | The relationship is weaker than the discourse assumes, and it's mostly buying *floor*, not ceiling. | Payroll vs. wins scatter with a shockingly flat line |
| 3 | **The System** | He's a system quarterback. | The label is applied almost exclusively to one kind of player, and predicts nothing. | Grid of QBs labeled "system" vs. actual EPA |
| 4 | **Fourth Down** | Coaches have finally embraced analytics on fourth down. | They've moved, but nowhere near optimal, and the gap costs measurable wins. | Go-rate vs. optimal-go-rate, decade curve |
| 5 | **The Injury Tax** | Contact injuries are random, so you can't roster-plan around them. | Some are, some are extremely not, and the difference is worth real money. | Injury-rate distribution with a fat tail |
| 6 | **Defense Wins** | Defense wins championships. | Depends entirely on the era — the claim was true once and stopped being true on a date you can name. | One line crossing another, with the year circled |

### Tier 2 — The NIL and portal lane (your stated interest, genuinely underserved)

`[MEDIUM confidence]` The 2026 cycle had roughly **3,667 players in the portal out of
14,070 total**, and CFB moved to a **single primary transfer window, January 2–16**.
Combined with House-settlement revenue sharing and the roster-cap era, this topic
regenerates itself indefinitely. It's the rare evergreen that is also permanently
newsworthy. Verify those numbers before publishing them.

| # | Title | Belief on trial |
|---|---|---|
| 7 | **The Cap** | Revenue sharing will level the playing field. |
| 8 | **One Window** | Consolidating to a single transfer window fixes roster chaos. |
| 9 | **The Middle Class** | NIL killed the mid-major. |
| 10 | **Loyalty** | Players don't develop anymore because they transfer instead. |
| 11 | **The Collective** | Collectives are just boosters with paperwork. |
| 12 | **Draft Capital** | The portal is a better talent market than recruiting ever was. |
| 13 | **Home Field** | Realignment killed the rivalry, and the rivalry was worth wins. |

### Tier 3 — The recurring NFL arguments (pre-build, publish into spikes)

These are the ~20 arguments. Build the model once, hold the piece, publish when the
discourse comes back around — and it always comes back around.

| # | Title | Belief on trial |
|---|---|---|
| 14 | **The Ceiling** | You can't win a Super Bowl paying a quarterback top-of-market. |
| 15 | **Clutch** | Some quarterbacks are clutch. |
| 16 | **The Blueprint** | There's a blueprint to beat this offense; teams just don't execute it. |
| 17 | **Rest** | The bye week is worth a win. |
| 18 | **Momentum** | Momentum is real within a game. |
| 19 | **The Rookie Wall** | Rookies hit a wall in November. |
| 20 | **Coaching Trees** | Assistants from good staffs become good head coaches. |
| 21 | **Home Cooking** | Home field advantage is shrinking. |
| 22 | **The Trenches** | Games are won in the trenches. |
| 23 | **Prime Time** | Some teams can't play in prime time. |
| 24 | **The Sophomore** | Year two is the leap year for receivers. |
| 25 | **Run It Back** | Continuity beats talent. |

### Tier 4 — Your existing work, extended

You already have five finished pieces and a body of published research. These are the
cheapest videos you will ever make, because the analysis is done.

| # | Title | Source |
|---|---|---|
| 26 | **Against the Book** | The hub piece as a video — the flagship, the series thesis |
| 27 | **The Grind** | Already written. Establish the run. |
| 28 | **The Tell** | Already written. Andy Reid, the readable genius. |
| 29 | **Cold Snap** | Already written. Icing the kicker. Great null-result piece. |
| 30 | **Two-Minute Panic** | Already written. Timeout discipline, names named. |

Plus, off the README, two more that need no new analysis: **the Draft Sharpe series** and
the two **Big Data Bowl** projects (PASTA, CAMO). Those are credential pieces — they say
"this person is the real thing" better than any intro ever could.

---

## Packaging

`[MEDIUM confidence — verify with your manager friend]`

### Titles

- **Name-led.** Put the player or team in the title; it's the search anchor.
- **Number-led.** A specific strange number is the strongest curiosity gap available to a
  data channel.
- **Contrarian but falsifiable.** Argument titles beat neutral ones — but the argument has
  to be one you can actually prove, or retention collapses when you can't deliver.
- **Keep the payload in the first ~45–50 characters.** Mobile and TV truncate.
- **Living-room viewing keeps growing.** Titles and thumbnails must be legible from ten
  feet. This favors your format — 12-minute sit-back essays — and disfavors dense
  cluttered thumbnails.

### Thumbnails

Faceless is not a CTR death sentence — Secret Base, Tifo and JxmyHighroller all prove it
at seven figures of subscribers. But you lose the strongest attention primitive, so
replace it with something equally arresting.

- **The chart is the face.** One bold, weird, legible data shape. A visibly strange graph
  is your shocked-face equivalent.
- **0–3 words, huge.** Never repeat the title.
- **One dominant hue**, high contrast, team colors when relevant.
- **Avoid red arrows and circles.** Reads as low-effort and fights the magazine
  positioning you've already established in the articles.
- **Use YouTube's native Test & Compare** for thumbnail A/B testing once monetized. Free,
  and the highest-leverage packaging tool you'll have.

### Benchmarks to clear

`[MEDIUM — treat as directional; two research passes disagreed on the AVD band]`

| Metric | Target |
|---|---|
| CTR | 4–6% healthy. Below ~3% on broad impressions and distribution throttles. |
| APV on 12 min | 50%+ strong, ~40% workable, below 35% no browse traffic |
| **Retention at 0:30** | **75–80%+. The single most diagnostic number on a new channel.** |

If you're bleeding 30%+ in the first thirty seconds, nothing downstream matters. Fix the
hook before you touch anything else.

One useful reframe: **absolute watch-time minutes is what browse optimizes for.** A
12-minute video at 45% beats a 6-minute video at 70%. That's the real argument for longer
pieces — but only once you can hold retention. Earn the runtime.

---

## The competitive read

`[MEDIUM — subscriber counts verified where noted]`

Your actual competitive set, and what to take from each:

- **JxmyHighroller** (~2.45–2.62M subs) — faceless, voiceover-only, stat-and-chart-driven
  NBA argument essays, 8–15 minutes, 1–2 per week. Repeatedly covered as out-drawing ESPN
  on NBA video views. **This is your template with a different sport, and you have
  credentials he doesn't.**
- **Secret Base / Jon Bois** (~1.51M) — fully faceless, charts and spreadsheets and maps.
  But project-based, months between drops. **They are not defending the weekly cadence.**
- **Tifo Sports** (~1.78M) — faceless animated tactical explainers, 6–12 min. Proof the
  format scales.
- **Rabona TV** (~326K) — mid-size faceless essay channel. Study its packaging; it's at a
  scale you can realistically reach.

**The unoccupied square: "Dorktown, but weekly, and about the current NFL season."**

The NFL analytics community — EPA/CPOE, nflfastR, Next Gen Stats, the Big Data Bowl orbit
— is large, credentialed, high-income, and lives almost entirely on X and in Substack.
**It has no YouTube-native voice.** Warren Sharp, Ben Baldwin, the PFF and Sumer analysts
— none have built a real YouTube presence. That's the arbitrage, and your Big Data Bowl
placings are what make "faceless" read as *authoritative* rather than *AI slop*, which in
2026 is the whole difference.

Two things worth verifying yourself, since the research couldn't: the House of Strauss and
OutKick pieces on JxmyHighroller are the best available case study for your exact format.

---

## Daily protocol

The hour, every day:

```
0:00–0:05   daily-topic     Three pitches. Pick one. Timebox it hard.
0:05–0:15   validate-idea   Lock title + thumbnail. No analysis before this.
0:15–0:50   The work        Analysis, or writing, or charts, or edit — one thing
0:50–1:00   Package/ship    Or log where you stopped so tomorrow starts instantly
```

The single rule worth enforcing: **never start analysis before the title and thumbnail
are locked.** Paddy Galloway's version — *"always plan your title and thumbnail before
recording; everyone knows this, few do this"* — and MrBeast's production doc says the same
thing structurally. If you can't write a title that would make *you* click, the analysis
doesn't matter, and you've saved yourself twenty hours.
