# Design Brief — Criteria and Constraints

The engineering problem, restated after the footage pivot. This is the document the
skills are built against; when it changes, they change.

Status: **draft, in active revision.** Open questions are marked `❓` and are the things
worth arguing about next.

---

## 1. The product, in one sentence

> A sports explainer channel that gives people — from teenagers to their fathers — the
> shared language and honest evidence to settle the arguments they're already having.

Not a takes channel. Not a highlights channel. Not a stats account. The output is
**resolution**: you watched twelve minutes and now you can end a debate, or you
understand why it can't be ended.

## 2. The audience

This is the sharpest thing in the brief and everything else should serve it.

**Primary:** people who grew up reading ESPN The Magazine. That's roughly 30–45 now — the
Mag ran 1998–2019. They remember when sports writing had design, ambition, and a point of
view, and they've watched that get replaced by aggregation and screaming.

**Secondary, and the growth engine:** Gen Z and Gen Alpha. They have never had the Mag.
They have TikTok clips and debate shows. They are, contrary to the stereotype, *extremely*
receptive to long-form explainers — Veritasium, Kurzgesagt and 3Blue1Brown are built on
young audiences sitting through twenty minutes of genuine difficulty.

**The bridge is the actual product.** A dad and his kid arguing about whether the run game
matters is the exact use case. The video is the thing they both watch and then quote at
each other. That's a real and underserved job.

Design consequences:

- **Never condescend in either direction.** No "as you probably know" and no "let me
  explain what a quarterback is."
- **Assume fluency in sports, not in statistics.** They know what a third down is. They
  do not know what EPA is, and they will not tolerate you pretending they should.
- **Every piece must be watchable by someone who disagrees.** If a believer feels dunked
  on in the first thirty seconds, you've lost half the audience and all of the utility.
- **Settle-ability is the metric.** After watching, can they state the finding in one
  sentence to someone else? That sentence is the reversal, and it's why `validate-idea`
  gates on it.

## 3. Tone

Target: **rigorous explainer structure, sportscaster warmth.**

The references, and what each contributes:

| Source | What to take |
|---|---|
| **Fern** | Near-weekly documentary cadence at real research depth. Proof the volume is possible. |
| **Veritasium** | Misconception-first structure. Start where the viewer's wrong belief is, not where the answer is. |
| **3Blue1Brown** | Build intuition before formalism. The viewer should *feel* the result before seeing the number. |
| **Kurzgesagt** | Visual system as identity. Total consistency of design language across every video. |
| **Jon Bois** | Charts as narrative. Deadpan warmth. Permission to be strange. |
| **Stuart Scott** | Cultural fluency and joy. Sports talk that sounds like how people actually talk. |
| **Scott Van Pelt** | The "One Big Thing" monologue — earned, conversational, lands a point without shouting. |

**The conflict, which has to be resolved rather than ignored:** Kurzgesagt's narrator is
omniscient and neutral. Veritasium's is first-person and frequently *wrong on purpose* —
"I believed this, here's why I was wrong." Bois is a deadpan absurdist. Stuart Scott was
pure personality. **You cannot be all four simultaneously.** That's a costume, and
audiences detect it instantly.

`❓ Open question — this is the most important unresolved decision in the brief.`

My recommendation: **first person, curious, occasionally wrong, warm.** Concretely —

- **Veritasium's stance**, because it maps perfectly onto belief-on-trial. "I thought
  establishing the run mattered. I tested it five ways. Here's where I was wrong, and
  here's the one place the old coaches are right."
- **3Blue1Brown's pedagogy**, because your audience is sports-fluent and stats-naive, and
  intuition-before-formalism is exactly how you bridge that.
- **Bois's chart-as-story instinct** and permission to let a graph be the punchline.
- **SVP's register** — the voice of a guy who knows the sport cold, talking to you at a
  bar, not performing at you. This is the *delivery*, and it's what stops the above from
  reading as a lecture.
- **Stuart Scott's warmth and cultural fluency**, used sparingly. His genius was that the
  references were *native*, not inserted. Forced catchphrases are the single fastest way
  to sound like a costume.

**What to drop: Kurzgesagt's omniscient neutrality.** It's incompatible with first-person,
and neutrality is the wrong stance for a channel whose entire premise is having done the
work yourself. Keep their *visual* discipline, discard their *narrative* stance.

`❓ Does the existing written voice survive the translation?` The articles are third-person
and clipped — "Nobody breaks." "The joke has it backwards." The video voice being warmer
and first-person is probably correct, but it means the article and the script are genuinely
different registers rather than one text read aloud. Worth deciding deliberately.

## 4. The footage decision, revised

**Previously this brief assumed no game footage. That's changed — footage is in.**

Being explicit about what that costs, because it's a real trade and the earlier
recommendation wasn't wrong, it was answering a different question:

**What you gain:** the thing that makes sports *sports*. You cannot explain a play with a
chart alone, and the audience — especially the younger half — expects to see the thing
being discussed. It also unlocks the emotional register that Stuart Scott's voice needs.
A chart cannot be joyful.

**What you give up:** the structural immunity. A charts-only channel sits entirely outside
Content ID, which is a genuinely rare position. Adding footage means claims become a
routine operating cost rather than a non-event.

**Why it's still probably right:** the immunity was worth a lot *if* the format could
carry the audience without footage. The evidence that it can is real but narrow — Bois and
Tifo do it, and both took years to build the visual language that substitutes for footage.
You have one hour a day. Footage is the faster path to a watchable video, and you have a
friend who already knows the practical limits.

**So the discipline shifts from avoidance to compliance.** That's what the
`footage-policy` skill is for: a league-by-league decision table plus a deterministic
checker, so clip decisions are rule-driven instead of vibes.

Working principles until the research lands:

- **The charts stay the spine.** Footage illustrates; charts carry the argument. This is
  both an editorial and a risk position — the video must still be a new work, not a
  substitute for the broadcast.
- **Leagues differ enormously.** MLB has been permissive enough that a whole business got
  built on frame-by-frame breakdowns; the NFL is among the most aggressive claimants on
  the platform. **Do not port the Jomboy playbook to the NFL.**
- **Broadcast audio is frequently the actual trigger** — the music, not the picture. Mute
  and narrate.
- **A claim is not a strike.** Claims divert revenue on one video. Strikes endanger the
  channel. Keep those two risks separate in your head and in the skill.

`❓ Open question: what's the acceptable claim rate?` If 20% of videos get claimed and lose
their ad revenue, is that a cost of business or a broken model? This should be a number in
the brief, not a feeling — it determines how conservative the checker is.

## 5. Cadence

The binding constraint, and the one most likely to kill this.

**Available:** 1 hour/day → 5–7 hours/week.
**Cost of a 12-minute chart-and-footage explainer:** 13–26 hours the first few times,
8–13 hours systematized.

Which means 12 minutes weekly is **not achievable** at one hour a day, and pretending
otherwise is how this ends.

**Corrected after the animation research.** An earlier draft of this brief suggested 6–8
minutes every 7–10 days. **That is not achievable and the number was wrong.** Measured
hours-per-finished-minute for a programmatic pipeline is 12–20 while learning and **2–4
once a component library exists** (see `.claude/skills/animate/references/stack-decision.md`).

So at one hour a day, honestly:

| Length | Intermediate hours | Real cadence |
|---|---|---|
| 6–7 min | 14–28 | **2–4 weeks** |
| 12 min | 24–48 | **4–7 weeks** |

And the first two or three videos take **three to four times** those numbers.

Three honest options:

| Option | Cadence | Trade |
|---|---|---|
| **A. Short and steady** | 6–8 min, every 2–3 weeks | Most reps, fastest learning, fewer mid-rolls |
| **B. Long and slow** | 12 min, monthly | Better ad load, slow feedback, easy to stall |
| **C. Hybrid** | Monthly 12-min flagship + articles between | Matches the hub-and-spoke you already built |

**Recommendation: A now, C later.** Ship 6–8 minute pieces every two to three weeks. You
need reps far more than runtime, and retention data from ten short videos beats three long
ones. Earn the twelve minutes.

**Articles are the cadence filler.** They're cheap for you — you're already writing them —
and they keep the series alive in the gaps where a video can't land. This is a further
argument for making the article the *research artifact* the script is cut from rather than
a second deliverable.

**The two-video investment that changes the math:** the theme file and the component
library. Hours-per-minute drops by roughly 4–5x once they exist. Building them is worth
more than the two videos you'd otherwise have made.

The counter-argument, which is real: **absolute watch-time minutes is what browse traffic
optimizes for**, and a 12-minute video at 45% retention beats a 6-minute video at 70%. So
length genuinely does pay — but only once you can hold it. Ship short until retention at
0:30 is consistently 75%+, then extend.

**The thing that actually buys cadence is tooling, not discipline.** The two artifacts that
collapse per-video time from 20 hours to 8 — the reusable ggplot theme and the Resolve
project template — are worth more than any two videos. Build them first.

`❓ Open question: does the article still ship with every video?` The articles are
genuinely good and cheap for you, but they're not free. Options: article with every video,
article only for flagships, or article as the *research artifact* that the script is cut
from. The third is probably right and makes the article a production input rather than a
second deliverable.

## 6. Money, restated

You want the ad money, so: ads are in scope and the format should serve them. But the
research is unambiguous that **ads are a minority stream at every scale** — 10–15% of a
sports channel's revenue in the modeled blend, and replacing your salary on AdSense alone
needs roughly 3–7M views a month, every month.

So the honest framing is **both/and**: build for ad revenue because it's real money that
arrives passively and validates the work, and build the newsletter in parallel because
sports converts to paid email better than any other vertical (1.93% median vs 0.62%
platform-wide) and ~2,500 paying subscribers is a six-figure business.

Full detail in `02-monetization.md`. Ad-relevant design consequences:

- Length matters for mid-roll load — this is the real argument for eventually getting to
  12 minutes.
- **Avoid the limited-ads triggers**, which for a sports debate channel are profanity and
  "controversial or sensitive topics." Limited ads cut a video's revenue 50–90%. Athlete
  legal trouble and politics-adjacent stories are the live risk. This is a content
  selection constraint, not just an editing one.
- Keep betting sponsors and betting affiliate out of season one — see `02-monetization.md`
  §7 on the employer question, which is unresolved and worth an hour with an employment
  lawyer.

## 7. Skill architecture

### The governing principle: the hour buys taste

The single most important constraint is that **one hour a day is not enough to make the
video — it is exactly enough to supply the judgment.** That's not a limitation to work
around, it's the design spec.

So the split isn't "automate what's easy." It's:

> **Anything a machine can do deterministically, a machine does. The hour is spent only on
> the things that require taste, and on nothing else.**

What taste means here, concretely — the irreducible human contribution:

- Deciding which belief is worth putting on trial, and whether you actually care
- Judging whether the steelman is *genuine* or a strawman wearing a costume
- Recognizing when a finding has a reversal and when it's just a number
- **Verifying that a number is right.** Never delegate this. LLMs hallucinate statistics
  fluently and confidently, and for an NFL analytics audience one wrong number is a
  credibility event you don't recover from.
- The analogy that makes an abstraction concrete — the Stuart Scott move
- Where the joke goes, and whether it survives the chart being removed
- Whether the title is a promise the video keeps

Everything else — data pulls, chart rendering, HTML assembly, loudness normalization,
captions, thumbnail compositing, clip compliance, metadata — is machine work. If you find
yourself spending the hour on any of it, the tooling has failed and fixing the tooling is
the higher-value use of the hour.

**This is also why the voice can be iterated rather than specified up front.** The
narration register in `style/narration-voice.md` is a starting position, not a finished
product. You'll refine it by making things and noticing what sounds like you. The
references get better; the machine layer stays constant.

### The mechanical split

The design principle you named, which is right: **decompose every task into what must be
judgment, what can be deterministic, and what must be consistent.**

```
.claude/skills/<name>/
  SKILL.md          the PROMPT — judgment only. What a smart person decides.
  references/       durable STANDARDS. Voice, policy tables, specs.
  scripts/          DETERMINISTIC automation. Code, not prose.
  templates/        CONSISTENCY artifacts. The thing output is built from.
```

The split for this pipeline:

**Judgment (stays in SKILL.md — never automate):**
Is there a reversal · is the steelman genuine · which verdict · title and thumbnail
concept · where the hook lands · which clip illustrates which beat · **whether a number is
right**

**Deterministic (scripts/):**
Data pull and cache · chart rendering through the theme · article HTML build from markdown
+ template · runtime estimate from word count · audio normalize to −14 LUFS · transcript
and captions · thumbnail compositing · **footage compliance check** · publish metadata
assembly

**Standards (references/):**
`house-style.md` · `voice.md` · `league-footage-policy.md` · `chart-spec.md` ·
`packaging-spec.md` · `verdict-vocabulary.md`

**Consistency (templates/):**
`article.html` (the ESPN-Mag shell) · `theme_atb.R` · the Resolve project · the thumbnail
template

**Why this matters for one-shot quality:** the references are the part you iterate. Every
time a video underperforms or a piece of writing misses, the fix goes into a reference
file, and every future generation inherits it. The SKILL.md prompt should change rarely;
the references should change constantly. That's the compounding loop you're after.

## 8. Channel name

Criteria: says "settles arguments," works for a 15-year-old and a 45-year-old, isn't
jargon, isn't taken, survives being said out loud, and doesn't box you into one sport.

Leading candidates:

| Name | For | Against |
|---|---|---|
| **Ball Knowledge** | Native Gen Z/Alpha vernacular meaning genuine expertise. Warm, a little funny, and quietly ironic for a data channel. Dads get it. Works across sports. | Very of-the-moment; may age. Check availability. |
| **The Receipts** | "We have the receipts" is exactly the settle-an-argument frame. Evidence-forward. Current without being try-hard. | Slightly combative — cuts against the steelman ethic. |
| **Against the Book** | Already yours. Strong, literary, ESPN-Mag-shaped. Series is built. | Debunk-shaped. Implies you always disagree, which isn't the ethic. |
| **Prove It** | Short, punchy, universal. The argument-settling frame in two words. | Generic; likely contested. |
| **Run the Sims** | Your existing handle. Brand continuity, and the analytics crowd already knows it. | Jargon for the mass audience. Signals "stats guy," not "sports storyteller." |

My pick: **Ball Knowledge** as the channel, **Against the Book** retained as the flagship
series. That gives you a warm, broad front door and a rigorous named franchise behind it —
the same structure as *Secret Base* holding *Dorktown* and *Chart Party*.

`❓ Needs an availability check across YouTube, X, and domains before committing.`

## 9. Open questions, ranked

1. **Narrative stance** (§3) — first person or omniscient? Everything downstream depends
   on it.
2. **Acceptable claim rate** (§4) — what percentage of claimed videos is a functioning
   business?
3. **Does the article ship with every video, or become the research input?** (§5)
4. **Channel name availability** (§8)
5. **The employer question** (`02-monetization.md` §7) — unresolved, and the only one with
   real downside risk.
