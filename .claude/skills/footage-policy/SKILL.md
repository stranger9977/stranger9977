---
name: footage-policy
description: Decide whether specific game footage is safe to use, league by league, and produce a compliant clip manifest before editing. Use when planning which clips go in a video, when a claim arrives, or when deciding whether to dispute. Triggers on "can I use this footage", "is this clip safe", "I got a copyright claim", "should I dispute", "plan the clips".
---

# Footage policy

Decide what footage goes in the video, and what the risk actually is. This skill exists
because the folklore in this space is wrong in specific, expensive ways.

**Read `references/league-policy.md` for the full decision table and the evidence behind
it.** This file is the procedure; that file is the data.

## The model that explains everything

Three separate systems can hurt you. Creators conflate them constantly, and the
conflation is what causes bad decisions.

| System | Triggered by | Costs you | Evaluates fair use? |
|---|---|---|---|
| **Content ID** | Automated fingerprint match | Revenue **on that video** | **No** |
| **DMCA takedown** | A human at a rightsholder deciding to act | The video **+ a strike** | No |
| **YPP inauthentic-content review** | YouTube reviewing channel originality | **Channel monetization** | N/A |

**Content ID claims cost you money on one video. Strikes cost you the channel.** Three
strikes in 90 days is termination.

Almost all league enforcement against analysis channels is Content ID claims, which are
survivable indefinitely. The dangerous exceptions are documented in the reference file and
you should know them cold.

## The procedure

### Step 1 — Classify the source

| Source | Risk | Action |
|---|---|---|
| College coaching film / All-22 / school-provided | **STRIKE** | **Never.** The one documented strike-generator. |
| **Unlicensed press / wire stills** | **STRIKE** | Outside Content ID, so no auto-claim — but that leaves manual DMCA, the strike track. UFC sent 5 takedowns over stills. **License them.** |
| Live broadcast feed, any league | Claim near-certain | League rules, step 2 |
| A league's own YouTube highlight upload | Claim near-certain | Being on YouTube doesn't license you |
| Licensed program footage (NFL Access Pass, NBA/WSC) | **Zero** | This is the prize |
| Licensed stills (Imagn, Icon Sportswire, IMAGO, Getty) | **Zero** | Affordable, unlike video |
| **Original animation, data viz, diagrams, your own camera** | **Zero** | **The backbone.** No reference file exists, so nothing can match. |

**Animation is the only genuinely free lunch here.** Content ID matches against reference
files, and references are audio/visual/audiovisual works supplied by rightsholders.
Original animation has no reference anywhere in the system. It's why Fern's whole channel
is Blender reconstruction, and it's a moat rather than a compromise because it's hard to
copy.

**Stills change the shape of the risk, not the size.** No automated claims, but what's left
is manual DMCA — low frequency, high severity, and it's the track that ends channels.
See `references/league-policy.md` for the full comparison and licensing options.

### Step 2 — Classify the league

Short version; full table with sources in the reference file.

| Tier | Leagues | Posture |
|---|---|---|
| **Safest** | NBA | Permissive by stated policy, real creator program |
| **Workable** | NFL, MLB | Aggressive claims, low strike risk, NFL has the best licensed door |
| **Avoid footage** | NHL, UFC, soccer (PL/UEFA/FIFA), F1, **NCAA/CFB** | Aggressive, and several have documented strike cases |

### Step 3 — Set the per-video budget

- **Zero claimable footage** → publish freely. This is the baseline format.
- **NBA footage** → publish, accept a possible monetize-claim.
- **NFL or MLB footage** → **upload unlisted first to surface matches.** If claimed to
  *monetize*, publish anyway when the video's job is audience growth. If claimed to
  *block*, re-cut.
- **Tier-3 league footage** → don't publish with it. Substitute stills, diagrams,
  animation.

### Step 4 — Decide on disputes

- **Never dispute a monetize-claim from an aggressive league.** You're gambling a
  one-video revenue loss against the claimant escalating to a strike. Bad trade.
- **Do dispute block-claims.** The video is worth zero either way, and the claimant has
  30 days to respond — silence releases the claim.
- Track your strike count as the single most important channel metric. **Never carry two
  live strikes while publishing footage-heavy content.**

## What actually works, and what's superstition

### Folklore — stop doing these

- **"Under 7 seconds is safe."** Pure myth, and traceable to SEO content farms. YouTube
  publishes no duration safe harbor and partners configure their own thresholds. Content
  ID matches very short segments.
- **Zoom, crop, mirror, flip.** Fingerprinting is robust to all of them.
- **Speed changes (95%, 103%).** Same. Audio ID explicitly survives pitch-shift.
- **Telestration, arrows, circles, screen-in-screen.** These do **nothing** for detection.
  Do them — but for the right reason: they support fair use and they satisfy YPP
  originality review.
- **"Transformative use prevents claims."** Content ID cannot evaluate fair use. It is a
  fingerprint matcher. Transformation changes your legal position, not your detection
  probability.

### Real — these do something

- **Muting broadcast audio** — real, but misunderstood. It kills the **music** claim
  (arena music, walk-up songs, broadcast beds carry *separate* music-industry references).
  It does **not** stop the league's audiovisual reference from matching. Mute and narrate,
  but don't expect it to save you from the league.
- **Unlisted test upload** before publishing. Surfaces matches while you can still re-cut.
  Costs nothing. Do this every time.
- **Original commentary and editorial structure.** Protects channel-level monetization
  under YPP, which is a separate and more serious risk than any single claim.
- **Licensing.** The only thing that actually works.

## On fair use, honestly

Sports commentary is genuinely strong on factors 1 and 2 — criticism and comment are
enumerated, and live sports are factual events. It is **weak on factor 4**, market effect,
because leagues license official highlight products and a court could find your clip-heavy
video substitutes for one.

Almost nothing is litigated squarely on point. The nearest analog, *Hosseinzadeh v. Klein*
(S.D.N.Y. 2017), found a commentary video fair use — but **expressly refused to hold that
reaction videos are categorically fair use.**

Three errors to avoid:

1. **Fair use is not a shield against Content ID.** It's a fingerprint matcher with no
   legal reasoning.
2. **Fair use is an affirmative defense**, not a right. You assert it after being sued,
   having already paid a lawyer.
3. **"Commentary" is not a magic word.** The analysis is holistic and factor 4 works
   against you.

Nobody in the documented record won on fair use in court. Successful defenses were
**counter-notice and outlast** (the claimant won't sue) or **negotiate** (you're big
enough to be worth talking to).

## Output — the clip manifest

Produce `channel/scripts/<slug>.clips.yaml`, then run the checker:

```bash
python .claude/skills/footage-policy/scripts/check_clips.py channel/scripts/<slug>.clips.yaml
```

```yaml
video: the-portal
clips:
  - id: c1
    beat: "cold open — the belief"
    source: broadcast          # broadcast | coaches_film | league_upload
                               # | licensed_program | licensed_stock | original
    league: NFL
    duration_s: 6
    audio: muted
    treatment: "telestrated, narrated over"
  - id: c2
    beat: "the concrete example"
    source: original           # own chart animation
    league: none
```

The checker is deterministic. It flags strike-risk sources, tallies per-league exposure,
and refuses to pass a manifest containing college coaching film. It does not replace
judgment about whether a clip earns its place — that's yours.

## The long game

The single most valuable finding in the research, and it corrects the story most creators
tell themselves:

**Jomboy was never protected.** MLB sent annual mass violation notices and claimed the
revenue on his videos, including the lip-reading breakdowns — and won, even against fair
use claims. He built the business anyway, on podcasts, merch and live events, while MLB
took the YouTube ad money. In June 2025 MLB acquired a minority stake, which *then* cleared
his channel to use league footage. It took four years to negotiate.

That is not a legal template. It's an acquisition outcome. He was claimed for years, got
big enough that the league found it cheaper to buy in than to fight, and got cleared after.

**So play it the way he actually played it:** build the audience on formats that can't be
claimed — data visualization, animation, diagrammed reconstruction, licensed stills,
original interviews — use footage as seasoning, and treat **league creator programs as the
real prize.** The NFL Access Pass and the NBA/WSC network are the only two documented doors
that convert "claimed forever" into "cleared and monetized." Both are curated, which means
the qualification is audience and quality, not paperwork.

Your Big Data Bowl placings are a real credential to apply with.
