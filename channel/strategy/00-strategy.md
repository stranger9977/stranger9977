# Against the Book — Channel Strategy

The engineering design process applied to a YouTube channel: define the problem and the
constraints, survey what's actually known, pick a design, build a testable prototype,
instrument it, iterate on the numbers.

**Read the confidence notes.** This session's web research hit a hard wall — the search
budget was exhausted and outbound fetches were blocked by egress policy — so some of
what follows is well-sourced and some is not. Every claim below is tagged. Do not treat
a `[LOW]` number as a plan input, and check those specifically with your YouTube manager
friend, who is a better source than any blog on the current meta anyway.

---

## 1. The problem

Build a sports channel that produces enough income to replace a Senior Data Scientist
salary, starting from one hour a day, without appearing on camera.

### Constraints

| Constraint | Value |
|---|---|
| Time, phase one | 1 hour/day |
| Capital | ~$0 until the channel is profitable |
| On-camera | No |
| Own voice | Disliked by the creator, unresolved — see `01-voice.md` |
| Format | 12-minute narrated explainers, ESPN-The-Magazine feel |
| Existing assets | 5 finished *Against the Book* articles, 2 videos near-ready |

### The constraint that isn't real

One hour a day is not enough time to research, analyze, write, design, narrate, and edit
a 12-minute video. That is roughly 8–15 hours of work per video for most people making
this kind of thing.

That is fine, and it is not a problem to solve — it is a **cadence** to accept. One hour
a day is five to seven hours a week, which is one good video every two to three weeks
once the pipeline is tuned. Plan for that. The failure mode is promising yourself weekly
uploads, missing, and quitting.

---

## 2. What you actually have (the honest inventory)

This is where the strategy diverges sharply from generic faceless-channel advice, and
it's worth being blunt about it: **most of that advice does not apply to you.**

You are not a person picking a niche to arbitrage ad revenue. You are:

- A Senior Data Scientist at Penn Entertainment building NFL and NCAA simulation and
  pricing models
- NFL Big Data Bowl **runner-up (2024)** out of 300+ submissions, and honorable mention
  (2025) in a record 400+ field
- Already publishing original research that got featured on YouTube (Draft Sharpe)
- The author of five finished pieces — *Against the Book*, *The Grind*, *The Tell*,
  *Two-Minute Panic*, *Cold Snap* — that are, straightforwardly, better than what most
  sports channels put out

The five articles are the proof. *Cold Snap* is a piece about a null result that stays
interesting for 700 words, and its Pete Carroll section is a multiple-comparisons
lesson smuggled into sports writing. Nobody making AI slop can produce that. Nobody
*without* your job can produce that.

**The moat is that the analysis is real and nobody else can run it.** Everything in
this strategy follows from protecting that.

---

## 3. The structural advantage nobody tells you about

`[HIGH confidence — this is the best-sourced finding in the research]`

The single largest financial risk in sports YouTube is Content ID. The mechanics:

- Content ID is a pure fingerprint match. **It does not evaluate fair use.** The burden
  is entirely on you to dispute after the fact.
- On a match, the rightsholder chooses: block the video, **divert 100% of ad revenue to
  themselves**, or track it.
- The **NFL is named among the most aggressive enforcers on the platform.** The NBA,
  FIFA and UFC upload full game broadcasts into Content ID, so matching is near-total.
- Content ID handles over 98% of YouTube copyright actions.

Most sports channels are built on game footage. They live with claims, mute broadcast
audio, keep clips under seven seconds, and hope. Some of their revenue goes to leagues
by default.

**Your format uses no game footage at all.** It's your own R/ggplot charts, your own
motion graphics, your own writing, your own analysis. Your Content ID exposure is
effectively zero.

That is not a small edge. The gap between sports RPM and finance RPM is maybe 5x. **The
gap between a claimed video and an unclaimed one is 100% of the revenue.** You start
with the second problem already solved, permanently, by a format choice you made for
aesthetic reasons.

Protect this deliberately. The temptation to drop in a highlight will be constant.
Don't. The charts *are* the show — that's the Jon Bois lesson.

### The adjacent opportunity

`[MEDIUM confidence]` The NFL runs an **Access Pass** program giving selected creators
pre-approved, officially licensed game footage they can monetize. There's a "Legends"
tier for former players. If you ever want footage, that program — not fair use — is the
route. Your Big Data Bowl placings are a genuinely strong credential to apply with.

---

## 4. The monetization policy question, settled

`[HIGH confidence]` You asked whether faceless content gets demonetized. The short
answer is no, and most of what's written about this online is wrong.

**What actually happened:** In July 2025, YouTube renamed its "repetitious content"
policy to **"inauthentic content."** A wave of headlines called it an AI ban. It wasn't.
Rene Ritchie, YouTube's Head of Editorial and Creator Liaison, called it *"a minor update
to YouTube's longstanding YPP policies to help better identify when content is mass
produced or repetitive."* The reused-content policy was **explicitly unchanged**, and
commentary, clips, compilations and reactions were explicitly unaffected.

In July 2026, YouTube clarified further, splitting inauthentic content into three
buckets:

1. **Generic or repetitive** — near-identical videos from AI, CGI or templates;
   templated scripts with minor substitutions; slideshows with little narration.
2. **Unsatisfying or off-putting** — emotionally manipulative formulas; mimicking
   existing formats so closely that videos "feel interchangeable"; content designed to
   shock purely for views.
3. **AI personas presenting as human experts on sensitive topics** — synthetic doctors,
   lawyers, financial advisers, political experts.

**Nothing in any of this keys on synthetic voice.** There is no documented rule anywhere
in YouTube's policy text that demonetizes AI narration. "AI voice gets you demonetized"
is folklore. YouTube's own stated position is that disclosing synthetic content *"does
not by itself limit the audience or remove monetization eligibility."*

The safe harbor, from the reused-content policy, is a three-part disjunctive test — you
need at least one, meaningfully:

> significant original commentary · substantive modifications · educational or
> entertainment value

Notably, YouTube's own monetizable example is content where **"the creator is either
visible in the content *or* explains how the creator added to the content."** On-camera
presence is explicitly not required. Faceless is fine.

**You clear this bar by a wider margin than almost anyone on the platform.** Original
analysis, original charts, original writing, a named credentialed author, per-piece
bespoke design. The one bucket worth watching is #2 — don't let the format calcify into
something interchangeable. The fact that *The Grind*, *The Tell*, *Two-Minute Panic* and
*Cold Snap* each have a completely distinct visual identity is, accidentally, exactly the
right instinct.

One caveat worth stating plainly: this is enforced **at the channel level**. A handful
of lazy videos can jeopardize monetization for everything. Which is another argument for
the slow cadence.

---

## 5. Choosing the lane

### The money, with honest error bars

`[LOW confidence on levels, MEDIUM on ordering]` Every "sports RPM" number traceable
online leads back to a cluster of SEO content farms that cite each other. Neither vidIQ
nor Mediacube publishes a sports-specific figure at all, which is itself informative.
Treat these as directional:

| Niche | RPM (US) |
|---|---|
| Personal finance / investing | $12–35 |
| Real estate, insurance, B2B software | $15–40 |
| Tech | ~$15 |
| True crime | ~$9 |
| **Sports analysis / commentary** | **$3–6** |
| Gaming, general entertainment | $1–5 |

Sports CPM ($6–15) is better corroborated than sports RPM and sits slightly above the
platform average of roughly $9, on the strength of the advertiser set — sportsbooks,
energy drinks, athleisure, streamers, QSR — and a desirable adult-male US demo.

**The actionable finding:** the spread *within* sports is larger than the spread between
sports and other niches. Sports **business, contract, CBA and analytics** content
borrows finance-adjacent CPMs. Generic compilations and low-context clips are at the
bottom. You are already positioned at the top end of your own niche — the NIL and
transfer-portal money story is, economically, a finance story wearing a college football
jersey.

### Seasonality — and why the timing matters right now

`[MEDIUM-HIGH confidence — this is structural, driven by ad budget cycles]`

- Q4 RPM runs roughly **25–35% above Q1**.
- US sports gets a compounding double peak: Q4 holiday ad spend lands exactly on the NFL
  stretch run and playoffs, then the **Super Bowl window delivers 2–3x CPM for about
  three weeks**, then NBA playoffs in May–June.
- The genuine dead zone for US sports is **late June through August** — post-NBA Finals,
  pre-NFL.

It is late July 2026. **You are sitting in the dead zone, which is the correct time to
build rather than launch.** Use August to bank a library. Publishing into the NFL season
opening with four or five strong pieces already live beats launching cold in October.

### The recommendation

**Lane: NFL analytics and conventional wisdom on trial, with college football's NIL and
transfer-portal economics as the second pillar.**

Reasoning:

- NFL is where your professional expertise and your data access already are.
- The *Against the Book* format is infinitely extensible — every sport has a book of
  unexamined beliefs, and you'll never run out.
- The NIL and transfer portal story is genuinely underserved by anyone who can do the
  economics rather than the outrage. It's the topic you said you actually care about,
  which matters more than any RPM table.
- CFB audiences are large and growing: `[MEDIUM]` the January 2026 national championship
  drew about 30.1M average viewers, quarterfinals averaged 19.3M (+14% YoY), and 11
  regular-season games topped 10M. Note sources disagreed on the exact YoY growth figures
  and I couldn't resolve it — don't publish those numbers without checking.

### A flag on the employer question

`[Not researched — raising it because it's the kind of thing that's expensive to
discover late]` You work at Penn Entertainment, which operates a sportsbook. Building a
public sports-analysis brand under your own name, using skills adjacent to your day job,
in a niche where the highest-CPM advertisers are sportsbooks, has obvious potential
entanglements — outside-activity policies, IP assignment, disclosure, and YouTube's own
gambling rules.

`[MEDIUM]` Separately: YouTube's November 2025 gambling policy overhaul carved out sports
betting content as an exception so it remains viewable, but it prohibits verbal
references to gambling sites not approved by Google. A channel that name-drops the wrong
sportsbook is exposed.

None of this is a reason not to proceed. It is a reason to read your employment
agreement before the channel gets big enough to matter, and to keep betting content out
of the first season entirely.

---

## 6. The five levels

This is the staged plan you asked for. The levels are gated on **capability and
evidence**, not on time — you move up when the previous level's exit criterion is met,
not when a calendar says so.

### Level 1 — Proof (now → ~5 videos)

*Goal: prove the format works and that you can sustain the pipeline.*

- Finish and ship the two videos that are nearly ready.
- Publish the five articles as a linked series with a real masthead.
- Build the library during the August dead zone; be live before Week 1.
- **Do not optimize anything.** You do not have enough data to optimize with.
- Ignore subscriber count entirely. Watch only: did you ship, and does the pipeline hold
  at one hour a day.

**Exit criterion:** five videos published, pipeline running without heroics.

### Level 2 — Signal (5 → 15 videos)

*Goal: find out which of your instincts about packaging are wrong.*

- Instrument everything. CTR and average view duration per video, and the retention
  graph shape — specifically where people leave.
- `[MEDIUM]` For a 10–20 minute video, roughly **35–45% average percentage viewed** is
  cited as competitive; at 12 minutes that's about 5:30 of average view duration. Caveat
  honestly: this benchmark comes from low-authority sources and I couldn't corroborate it
  with a human-authored one. Use it as a rough target, not gospel.
- Run the title and thumbnail *before* you make the video, every time. This is the single
  highest-leverage habit available to you — see Level 2's discipline below.
- Get YPP monetization on (thresholds change; check Studio, don't trust blogs).

**Exit criterion:** you can predict, better than chance, which of your ideas will
outperform.

### Level 3 — Compounding (15 → 40 videos)

*Goal: build the library that earns while you sleep, and add a second revenue line.*

- Lean into evergreen. A belief-on-trial piece stays true and stays searchable for
  years; a reaction to this week's game is dead in 48 hours.
- Start the email list. This is the asset YouTube can't take away and the one that makes
  going full-time survivable.
- Sponsorships become available. Sports business and analytics content attracts
  finance-adjacent advertisers.
- Consider the site. You said you'd hold off spending until full-time — correct call.
  Artifacts are fine until then.

**Exit criterion:** revenue is meaningful and not solely AdSense.

### Level 4 — Leverage (40+ videos)

*Goal: break the one-hour ceiling by removing yourself from the parts that aren't the moat.*

The moat is the analysis and the writing. Everything else is a candidate for delegation:
chart production, motion graphics, editing, thumbnail design, narration.

This is where money converts to time. Do not do it earlier — you can't brief an editor
on a style you haven't yet defined by making the thing yourself twenty times.

**Exit criterion:** revenue covers contractors and still pays you.

### Level 5 — Independence

*Goal: the channel is the job.*

Only now does the full-time question become a real decision rather than a fantasy. The
honest bar: replacing a senior data scientist salary in the US means clearing roughly
$180–250k gross. `[LOW]` At a $3–6 RPM that's somewhere in the range of 30–80M annual
views on AdSense alone — which is a hard number to hit and the wrong plan.

**The realistic path to Level 5 is not ad revenue.** It's the stack: AdSense plus
sponsorships plus a paid newsletter or product, with your credential doing work that a
generic creator's can't. Consulting, a data product, a subscription research tier. The
channel is the top of the funnel, not the business.

Be skeptical of any timeline. Documented 0-to-$10k/month case studies are dominated by
survivorship bias, and `[MEDIUM]` Paddy Galloway's advice to a channel starting from
zero is a **two-year horizon of consistent posting and improvement**. Plan for two
years. Be delighted if it's faster.

---

## 7. Cadence and quality

`[MEDIUM confidence]` There's an apparent contradiction in the expert advice worth
resolving, because getting it wrong is the most common way channels like this die.

Paddy Galloway's own channel: **33 videos in a decade, ~1.0M average views each.** His
stated principles are *"never publish a video you wouldn't rank in your channel's top
20%"* and *"one definitive video beats four forgettable ones."*

But his advice **for new channels is the opposite** — an *establishment phase* of
consistent posting to build the skill, then an *improvement phase* of strategy and
optimization.

Both are right, in order. Scarcity is a strategy for someone who has already learned to
make a great video. **You are in the establishment phase.** Post consistently at whatever
rate you can actually sustain, learn the craft, and earn the right to be scarce later.

Given one hour a day, that's a video every two to three weeks, plus articles in between.
Articles are cheap for you — you're already writing them — and they keep the series alive
between uploads.

---

## 8. Ideation is the job

`[MEDIUM confidence on the specific numbers, HIGH on the principle]`

The most consistent finding across every credible creator strategist: **the idea sets
the ceiling.** Reported framing from Paddy Galloway's work is that small creators spend
roughly 95% of their time on production and 5% on ideation and packaging, while top
creators spend around 30% on ideation and packaging. His rule, stated flatly:

> *"Always plan your title and thumbnail before recording. Everyone knows this, few do this."*

MrBeast's leaked production document says the same thing structurally — every video's
creative process starts with the title and thumbnail, and everything downstream is
defined against them.

This is why the morning hour starts with `daily-topic` and `validate-idea`, and why no
analysis begins until the title and thumbnail are locked. If you can't write a title
that would make you click, the analysis doesn't matter.

## 9. The first minute

`[HIGH confidence — direct quotes from the leaked MrBeast production document]`

The document calls the first minute *"the most important minute of each video,"* because
that's when people click off most, and says *"this is why we freak out so much about the
first minute and go so above and beyond to make it the best we freakin can."*

For calibration, it cites losing **21 million viewers in the first minute** against
roughly 60M clicks — about a 35% first-minute drop — and frames that as *better* than
platform average. So expect to lose a third of your audience in sixty seconds no matter
how good you are. Budget for it; don't be discouraged by it.

The structural takeaway that transfers: minutes 1–3, 3–6, and 6–end each have separately
defined jobs. The stated first-minute tactics are to match the expectation the thumbnail
and title set, front-load information about the video, and keep visual density high.

Applied to your format: open on the belief in a real voice, or on the single most
surprising number. Never open with a channel intro. See `write-script`.

---

## 10. What to check with your manager friend

The things this research genuinely could not settle, ranked by how much they'd change
your decisions:

1. **Current mid-roll ad mechanics.** Whether the 8-minute threshold still governs, how
   many mid-rolls a 12-minute video can carry, and what the retention cost is. Everything
   about your target length depends on this.
2. **Real sports RPM.** He has access to actual dashboards. Every public number is a
   content farm citing another content farm.
3. **Current YPP thresholds** and time-to-monetization.
4. **Whether 35–45% APV is actually the right target** for a 12-minute analytical piece,
   or whether that band is nonsense.
5. **Thumbnail conventions for sports in 2026** — face vs. no-face specifically, given
   you're faceless and your subject matter is charts.
6. **Whether chapters help or hurt.** Genuine trade-off, no A/B evidence found: chapters
   raise discoverability via Google Key Moments, but every timestamp is an exit point.

## 11. Sources worth opening yourself

These were identified but blocked by the egress policy in this session:

- MrBeast production doc — https://archive.org/details/how-to-succeed-in-mr-beast-production
- Paddy Galloway on Creator Science — https://podcast.creatorscience.com/paddy-galloway/ and https://podcast.creatorscience.com/paddy-galloway-2/
- Todd Beaupre, YouTube Director of Growth, on how the algorithm works — https://adoutreach.beehiiv.com/p/how-youtube-s-algorithm-really-works-in-2025-straight-from-youtube-s-director-of-growth
- YouTube monetization policies — https://support.google.com/youtube/answer/1311392
- Synthetic content disclosure — https://support.google.com/youtube/answer/14328491
- NFL Access Pass for creators — https://digiday.com/marketing/the-nfl-gives-creators-access-to-its-archives-for-content-creation-with-pre-approved-footage/
- vidIQ study on posting frequency across 10M channels — https://vidiq.com/blog/post/How-Often-Post-on-Youtube/
