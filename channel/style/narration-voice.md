# Narration Voice

The spoken voice, for video. Distinct from `house-style.md`, which governs the written
articles — those are third-person and clipped; this is first-person and warm.

Synthesized from Fern, Veritasium, 3Blue1Brown, Kurzgesagt, Jon Bois, Stuart Scott and
Scott Van Pelt. **You cannot be all of them.** This file resolves the conflicts and picks
a coherent register. Deviating from it is allowed; doing so by accident is not.

---

## The spec, in one block

- **Person:** first-person singular, fallible. "I thought." "I was wrong." "Watch this."
- **Address:** second person, constantly. Force a prediction before every reveal.
- **Humor:** deadpan, sourced from the data. About one dry line per 90 seconds.
  **Zero jokes in the 60 seconds surrounding the key explanation.**
- **Structure:** misconception trap (30–45s) → the one concrete example → the general
  result, delivered a half-beat *after* the viewer gets there → chart reveal as the
  emotional peak → 90-second closer in full voice.
- **Visual:** one persistent chart-as-set. Every motion means something. Spatial
  reconstruction when geometry matters.
- **Corrections:** when you're wrong, make it a video, not a pinned comment.

---

## 1. Why misconception-first (this is real research, not folklore)

Derek Muller's 2008 PhD at Sydney, *Designing Effective Multimedia for Physics Education*,
is the empirical backbone of the whole format. **364 first-year physics students**,
randomly assigned to four video treatments on Newton's laws:

| Treatment | Effect size vs. plain exposition |
|---|---|
| Exposition — concise, clear, lecture-style | baseline |
| Extended exposition — same plus extra material | ~baseline |
| **Refutation** — misconceptions explicitly stated and refuted | **d = 0.79** |
| **Dialogue** — student/tutor conversation covering the same | **d = 0.83** |

**The finding that matters is the null.** After the clear, well-made exposition, students
rated it "concise," "clear," "easy to understand," and reported **higher confidence** —
with **no measurable learning gain**. Clarity produced the *feeling* of understanding
without the fact of it. Muller's companion paper is titled "Raising cognitive load with
linear multimedia to promote conceptual change."

**Confusion is a feature.** You have to make the viewer's wrong model audible before you
can replace it. A video that explains the right answer beautifully and never names the
wrong one leaves the audience feeling smart and knowing nothing.

This is why the belief-on-trial format works, and it means the steelman isn't just an
ethical nicety — **it is the mechanism**. See `house-style.md` on steelmanning.

### The operational move: the pre-registered wrong answer

Before explaining anything, get the viewer to commit to a prediction you know is wrong.
Out loud, in their head, or via a proxy on camera. Veritasium's vox-pop — stopping
strangers and letting them be confidently wrong — is the Dialogue treatment
operationalized: it outsources the misconception to a third party so the viewer can hold
it without being humiliated.

Your equivalents: the coach quote, the broadcast cliché, the thing your father-in-law
says. Same function. The believer gets to be represented by someone else.

**Never gloat when the prediction fails.** The trap is set in a collaborative voice or it
doesn't work.

## 2. Concrete before abstract

Grant Sanderson's doctrine, and the title of his ODSC 2019 talk. From his Summer of Math
Exposition guidance:

- **Resist opening with the general result or the definition.** Examples precede
  generality.
- The inversion is deliberate. *Once you understand something*, you naturally hold the
  general framework and apply it to cases — which is exactly backwards for a learner, who
  has to build the framework out of a mind already populated with examples.
- **The strong version:** don't just give an example. Find *the type of example that
  guides the audience to rediscover the general result themselves.* Rediscovery, not
  delivery.
- **Open with the key exercise.** Don't save it for the end.
- **Topic choice matters far more than production quality.**

The transferable technique: **engineer the rediscovery.** Pick the one example from which
the viewer can derive the claim without being told, then shut up and let them get there
half a second before you say it.

Second technique, almost nobody does it: **the pause beat.** Explicitly stop and ask the
viewer to think. It converts passive watching into commitment.

For you this maps cleanly. The concrete example is always **one play, one drive, one
game, one coach's decision.** The abstraction is the 500,000-play model. Never open on
the model.

## 3. The conflicts, and what we picked

Four axes. Only some combinations close.

**Narrator's epistemic position — hard conflict.** Veritasium is a fallible first person
whose authority *comes from* being publicly corrected. Kurzgesagt is omniscient and
disembodied, never wrong in-frame, corrections quarantined to a separate meta-video. An
omniscient narrator who says "I was wrong" has destroyed the omniscience. A fallible
narrator who pronounces at cosmic scale reads as posturing.

→ **We take fallible first person. We steal Kurzgesagt's research *process*, not its
register.**

**Who the viewer is — soft conflict, resolvable.** Veritasium's viewer is a test subject
who is *meant* to be wrong. 3B1B's is a collaborator he wants to succeed. Both run on
prediction, so they compose — set the trap in a collaborative voice.

→ **Trap, but never gloat.**

**Humor — hard conflict.** 3B1B and Fern are functionally humorless and their credibility
is partly *made of* that absence. Bois's humor is load-bearing. Bois + 3B1B is the
sharpest incompatibility in the set: Bois wastes time beautifully, Sanderson wastes none.

→ **We take Bois's *source* of humor, not his pacing.** The absurdity must already be in
the data; you're pointing at it, not adding it. See the safety catch in §5.

**Pace versus reach — a real trade, not a style choice.** Veritasium and Fern engineer
retention hard and sit at 21M and 5.1M subs. Bois defies retention convention and sits at
1.5M with a devoted audience. If you want Bois's tone at Veritasium's scale you'll be
disappointed, and that disappointment pushes you toward packaging that over-promises —
the one move that kills an explainer.

→ **Bois's voice, Veritasium's structure. Accept that this caps the ceiling somewhat, and
don't chase the gap with the title.**

## 4. What every good explainer shares

Assembled from Muller's dissertation and Sanderson's guidance — the only two places this
is near-codified.

1. **Question-first, never topic-first.** Open on a state of not-knowing, not a subject
   announcement. This is Loewenstein's information-gap theory: curiosity is not a general
   appetite, it's tension from a *specific* missing piece. No specified gap, no curiosity.
2. **One spine.** One question per video. No branching.
3. **Nested open loops.** Main loop opens in minute one, closes in the last few. Smaller
   loops inside. The gap holds retention, not the pace.
4. **The visual is the argument.** Mute the video and you should still follow the shape of
   the reasoning. Sanderson's two rules: every movement is deliberate and has an
   identifiable purpose; every visual says the same thing the narration says.
5. **Low volume, high investment.** Fern's near-weekly cadence is purchased with sixty
   people. The grammar does not survive daily publishing.
6. **Epistemic hygiene is public.** Kurzgesagt deleted two of their most popular videos
   for failing their own standard — one on addiction, one on the 2015 migrant crisis —
   and *made a video about deleting them.* The self-correction is content.
7. **The last beat widens.** Never end on a summary. End one step past the finding, on
   what it means.

## 5. The sportscaster layer

### The merge point: Stuart Scott's real craft was simile

This is the insight that makes the blend coherent instead of a costume.

"Cooler than the other side of the pillow" takes an abstract quality — composure — and
grounds it in a concrete domestic sensation everyone has felt. **That is structurally the
same operation as an explainer analogy.** It is Sanderson's concrete-before-abstract,
executed with better rhythm.

So: **put the personality in the syntax, not the vocabulary.** Spend your sportscaster
instinct on the explanatory analogies — the comparisons that make an abstract finding
concrete. That's where the two traditions genuinely merge. Slang sprinkled on a rigorous
script is a careful person doing an impression.

Scott's own rule: **"I'm going to write how I talk. You might not get it, but there are
people who do get it."** He took hate mail over his delivery and didn't adjust. The
authenticity was the asset — and it is non-transferable by imitation. Which means: use
the references *you actually hold.* If you have to research whether a reference is
current, you don't have it.

### Steal SVP's container, not his words

"1 Big Thing" works because it's a **named slot with a fixed contract**. Van Pelt's own
description: *"two minutes of what I think about something"* and *"it's very much a
chameleon that can shift to something more silly, whimsical or whatever."*

In one season it covered honoring veterans, CC Sabathia entering treatment for alcohol
abuse, daily fantasy, and Jordan Spieth's hairline. **The container is what makes that
range legal.** Because the audience knows what the segment is, he can be silly Tuesday
and devastating Wednesday without whiplash.

→ Build one named recurring closer where you say what you actually think. A named slot
earns tonal range; a scattered catchphrase does not.

### The rules that keep it from being a costume

1. **Earn the joke with the number.** Bois's rule and the safety catch for the whole
   blend: the funniest line in the video should be a *factual observation*. **If the joke
   survives with the chart removed, cut it.**
2. **Sincerity ambush, exactly once.** Scott at the 2014 ESPYs, SVP on Sabathia, Bois at
   the end of a Dorktown — same mechanism: be funny, then drop it without warning. It
   works on contrast. Two sincerity beats and neither lands.
3. **Never let the catchphrase be the thesis.** Scott's ESPYs line — *"You beat cancer by
   how you live, why you live and in the manner in which you live"* — worked because it
   compressed an argument he'd already made and revised a text the audience already knew.
   A phrase deployed *before* the argument is a costume. The same phrase deployed *after*
   is a payoff.
4. **One register per video, not per sentence.** The blend dies from oscillation. It lives
   when the structure is Veritasium/Sanderson and the diction is uniformly yours.
5. **Personality owns the first 30 seconds and the last 60. Rigor owns the middle.**

## 6. Visual grammar

**Make the chart the set.** Don't cut to a graph — build one persistent visual space and
live inside it, so the emotional peak of the video is *a change in the chart*, not a
sentence of narration. Bois uses Google Earth as a canvas and a camera lens, not as a map,
flying between data points that exist as physical objects.

**Rebuild the space when geometry matters.** Fern's whole channel is Blender spatial
reconstruction — buildings and terrain rebuilt as navigable space with the camera moving
through them. For sports this is unusually apt: **a play diagram is a floor plan.** Route
combinations, coverage rotations, and defensive spacing are geometry, and geometry wants
3D.

**Write and design in the same pass.** Bois's actual workflow, from his Filmmaker
interview: *"we'll write a couple of script segments, design charts and arrange assets for
those segments, then move on to the next chunk."* Not script-then-visualize. And build one
master chart first — he describes it as a Christmas tree — then hang every other game,
stat, graph, image and quote on it.

**Footage illustrates; charts carry.** The video must be a new work, not a substitute for
the broadcast. This is simultaneously the editorial position and the copyright position.
See the `footage-policy` skill.

## 7. The shape of a video

```
0:00–0:45   THE TRAP        The belief in a real voice. Force a prediction.
                            Full personality. This is where the viewer decides.
0:45–2:00   THE STAKES      Why it matters, who holds the belief. Open the main loop.
2:00–4:00   THE STEELMAN    The best case for the belief. Genuine. No winking.
4:00–8:00   THE CONCRETE    ONE example — one play, one drive, one coach.
                            The viewer rediscovers the general result here.
8:00–10:00  THE ABSTRACT    Now the model. Delivered a half-beat after they got there.
                            Chart reveal is the emotional peak. No jokes in this window.
10:00–11:00 THE CONCESSION  What the other side gets right. Always give them something.
11:00–12:00 THE CLOSER      Named segment. Full voice. Widen past the finding.
```

Adjust proportionally for a 6–8 minute video; the order does not change.

## 8. Packaging, and the line not to cross

Veritasium's product/packaging split — the video is the product, the title and thumbnail
are the packaging, and packaging is *supposed* to be optimized — is legitimate and his
team runs continuous live A/B tests. One documented example: ~40 title and thumbnail
experiments over 10 days turning an underperformer into a top performer. He also reports
that **the best-performing title is often the more accurate and more useful one**, not the
more sensational.

But this is contested, and the criticism is worth internalizing rather than dismissing:
critics argue the frame rationalizes over-promising.

**The line: the title must be a promise the video keeps.** Over-promising is the single
move that dissolves everything else in this document. You are building a channel whose
entire value is that the analysis is honest. A title/payoff gap doesn't cost you a video —
it costs you the premise.

## 9. Sources

- Muller et al. (2008), "Saying the wrong thing: improving learning with multimedia by
  including misconceptions," *J. Computer Assisted Learning* —
  https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1365-2729.2007.00248.x
- Muller, "Raising cognitive load with linear multimedia to promote conceptual change,"
  *Science Education* — https://onlinelibrary.wiley.com/doi/abs/10.1002/sce.20244
- Muller's full PhD —
  https://www.academia.edu/18111353/PhD_Muller_Designing_effective_multimedia_for_physics_education
- Sanderson, "Concrete before Abstract" (ODSC India 2019) —
  https://confengine.com/conferences/odsc-india-2019/proposal/10273/concrete-before-abstract
- Sanderson, SoME guidance — https://3blue1brown.substack.com/p/some3-begins
- Bois on process, Filmmaker Magazine —
  https://filmmakermagazine.com/119858-interview-jon-bois-sb-nation/
- Formats Unpacked: Dorktown — https://www.formatsunpacked.com/p/formats-unpacked-dorktown
- Veritasium, "We Need To Talk About Clickbait" —
  https://www.veritasium.com/videos/2021/8/17/we-need-to-talk-about-clickbait
- Kurzgesagt, what we do — https://kurzgesagt.org/what-we-do
- Stuart Scott, 2014 ESPYs — https://speakola.com/sports/stuart-scott-espys-2014
- SVP on "1 Big Thing" —
  https://www.espnfrontrow.com/2015/11/1-big-thing-resonates-with-midnight-sportscenter-viewers/
- Loewenstein, information-gap theory of curiosity —
  https://www.cmu.edu/dietrich/sds/docs/golman/Information-Gap%20Theory%202016.pdf

**Confidence note:** Fern's craft philosophy is the weakest-sourced section here — no
primary interview located, so it's inferred from output plus trade coverage. Everything
attributed to Muller, Sanderson, Scott and Van Pelt is from primary or near-primary
sources.
