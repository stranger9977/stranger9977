---
name: write-script
description: Turn an Against the Book article into a narrated 12-minute video script with retention engineering, chart beats, and mid-roll-safe structure. Use when converting a finished article into a video, or when revising a script for pacing and retention. Triggers on "write the script", "turn this into a video", "script this piece".
---

# Write the video script

Converts a finished article into a narration script for a ~12-minute faceless video
built from charts and motion graphics. No game footage, no talking head.

**Read `channel/style/house-style.md` first.** The voice on camera is the voice on the
page. Same steelman, same verdict vocabulary, same honesty about nulls.

## Why 12 minutes

Long enough to carry mid-roll ads, short enough to hold retention on a single argument.
Do not pad to hit the number. A tight 9-minute video beats a bloated 12-minute one,
because average view duration is what the algorithm actually rewards. If the argument
only supports 9 minutes, ship 9 minutes.

**Verify the current mid-roll rules before optimizing around them.** YouTube has changed
mid-roll placement and the eligibility threshold more than once, and this file is not a
substitute for checking YouTube Studio's monetization tab or asking someone who manages
channels day to day. Structure the script so ad breaks land at natural section
boundaries and you will be fine under any version of the rules.

## Target shape

| Segment | Time | Job |
|---|---|---|
| Cold open | 0:00–0:30 | The belief, in a real voice. The promise. No channel intro. |
| Stakes | 0:30–1:15 | Why this belief matters and who holds it. Open the loop. |
| Steelman | 1:15–2:30 | The best case for the belief. Genuine. |
| Test 1 | 2:30–5:00 | First claim, first chart, first number. |
| Test 2 | 5:00–7:30 | Second claim. Escalate. |
| Test 3 | 7:30–9:30 | Third claim, or the trap/multiple-comparisons section. |
| The reversal | 9:30–11:00 | The payload. The idea turned inside out. |
| Concession + verdict | 11:00–12:00 | What the other side gets right. The verdict. |

Section boundaries at roughly 2:30, 5:00, 7:30 and 9:30 are your natural ad-break
points. Write so that a break at any of them does not sever a sentence or a reveal.

## Retention rules

**The first 30 seconds decide the video.** Open on the belief stated by a real person,
or on the single most surprising number. Never open with "Hey everyone, welcome back."
Never explain what the channel is. Never explain what you are about to explain.

**Open loops and close them.** State a question in the cold open that only gets answered
at the reversal. "The best play-caller in football is also the easiest to read. Here's
why that isn't a contradiction." The viewer stays to resolve it.

**One idea per beat.** Every 20–40 seconds, something changes — a new chart, a new
number, a new name, a turn in the argument. Not a gimmick cut; an actual change in
information.

**Name a person early.** Andy Reid in the first minute holds people who would bounce off
an abstract claim.

**Never front-load methodology.** Controls, samples and caveats go where they are needed,
in one clean sentence, not in a preamble. The full methods live in the description and
the article.

**Say the number, then say what it means.** "Minus two point nine points. That's about
three fewer points of make probability — and the confidence interval runs straight
through zero."

## Writing for the ear

This is narration, not prose. Read every line aloud.

- Shorter sentences than the article. Break any sentence you cannot say in one breath.
- Spell numbers the way you say them: "about three points," not "−2.9pp."
- No parentheticals. The ear cannot hear them.
- Repeat key numbers once. A reader can look back; a listener cannot.
- Contractions throughout. Written-out formality reads as stiff when spoken.
- Mark emphasis with *italics* so the narrator (or the voice model) knows the stress.

## Output format

Write to `channel/scripts/<slug>.md`. Two columns: narration and what is on screen.

```markdown
## COLD OPEN — 0:00

> **VO:** "You wear them down. Establish the run, impose your will, and by the fourth
> quarter, by December, they break."
>
> Every run-first coach in football has said some version of that.
>
> We tested it five ways. It loses four.

**ON SCREEN:** Black. The quote types in, one line at a time. Cut to the title card
on "five ways."

**BEAT:** 0:22

---

## STAKES — 0:30
...
```

Every beat carries a timestamp so total runtime is auditable. At the end of the script,
include a runtime tally and a word count. Narration runs about 150 words per minute, so
a 12-minute video is roughly 1,700–1,900 words of VO.

## Also produce

At the bottom of the script file:

- **Chapters** — timestamped, for the description. Chapter titles are hooks, not labels:
  "Nobody breaks" beats "Section 3."
- **Charts needed** — the list of visuals, in order, cross-referenced to the article.
- **Pull quotes** — three lines from the script that would work as Shorts hooks or as
  thumbnail text.

Then hand off to `package-video` for title, thumbnail, and description.
