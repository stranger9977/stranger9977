---
name: morning-hour
description: Run the full daily production hour end to end — topic selection, idea validation, the day's single work block, and shipping. Use to start or resume the daily session. Triggers on "start the morning hour", "let's do the hour", "run the daily", "what am I working on today".
---

# The morning hour

The orchestrator. One hour, every day, that moves exactly one thing forward.

**Read `channel/strategy/30-day-plan.md` for where you are in the arc, and
`channel/style/house-style.md` for the standard everything is held to.**

## First: figure out what day it is

Check `channel/ideas/wip.md` — the work-in-progress log. It says where you stopped
yesterday and what the next action is.

**If there's an open piece, continue it. Do not start a new topic.** The most common way
this fails is a backlog of half-built videos and nothing published. Finish before you
start.

Only run `daily-topic` when the previous piece has shipped or is genuinely blocked.

## The shape of the hour

```
0:00–0:05   Topic       daily-topic — three pitches, pick one. Timebox hard.
0:05–0:15   Package     validate-idea — lock title + thumbnail. Four gates.
0:15–0:50   The work    ONE thing: analysis, writing, charts, VO, or edit
0:50–1:00   Ship or log Publish, or write tomorrow's first action into wip.md
```

When a piece is already in flight, skip straight to the work block and give it the full
forty-five minutes.

## The one rule

**Never start analysis before the title and thumbnail are locked.** See `validate-idea`.
If you can't write a title that would make you click, you've just saved yourself twenty
hours.

## The work block — pick exactly one

Never two. The hour is too short to switch contexts and the switching cost is most of
what you have.

| Stage | Skill | Roughly |
|---|---|---|
| Analysis and charts | (R, your own tooling) | 2–4 hrs total |
| Draft the article | `write-article` | 1–2 hrs |
| Draft the script | `write-script` | 1–2 hrs |
| Record and clean VO | — | 0.5–1 hr |
| Edit | — | 3–4 hrs |
| Package and publish | `package-video` | 0.5–1 hr |

A 6–8 minute video is realistically 8–13 hours once systematized, so a piece is a two-week
project at this cadence. That's expected. See `channel/strategy/01-voice.md` §7 for why
starting at 6–8 minutes rather than 12 is the right call early.

## Always close the hour by writing wip.md

```markdown
# WIP

**Current piece:** The Portal
**Stage:** charts, 2 of 5 done
**Next action:** build the roster-turnover curve, pre- vs post-portal
**Blocked on:** nothing
**Locked title:** The Portal
**Locked thumbnail:** two turnover curves converging · text "THE SAME"
```

Tomorrow starts instantly instead of spending fifteen minutes remembering. Over a month
that's a whole extra work block.

## Weekly, not daily

Once a week, instead of a work block:

- **Instrument.** CTR, average view duration, and the shape of the retention graph on the
  last video. Specifically: where did people leave, and what was on screen there?
- Retention at 0:30 is the most diagnostic number you have. Target 75–80%+. If you're
  bleeding 30% in the first half-minute, fix the hook before anything else.
- Update `channel/ideas/backlog.md` with anything banked.

## What not to do in this hour

- Don't read about YouTube strategy. You have the strategy. Execute it.
- Don't tweak the channel art, the banner, or the about page.
- Don't check subscriber count. It tells you nothing at this stage and costs morale.
- Don't start a second piece because the first one is hard.
