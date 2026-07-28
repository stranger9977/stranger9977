"""Pull finished team-research agents out of the workflow transcripts.

The 32-agent research run writes each agent's result through a
StructuredOutput tool call. That call lands in the agent's own transcript
whether or not the orchestrator is still alive to collect it, so the
results are readable the moment an agent finishes rather than only when
the whole fan-out completes.

This matters practically: a 32-agent run takes over an hour and the
orchestrator can be orphaned by a context boundary. Harvesting from disk
is idempotent and can run as many times as you like while the rest
finish.

    python harvest.py            # -> reported.json
    python harvest.py --watch    # print progress only

The team is recovered from the agent's opening prompt, not from the
output, because a handful of agents omit the `team` field and return a
bare `battles` list.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

HERE = Path(__file__).parent
RUN = "wf_791b12f4-635"
TRANSCRIPTS = Path("/root/.claude/projects/-home-user-stranger9977"
                   "/9272c48e-b198-5502-875f-5aed7d8510f6/subagents/workflows") / RUN
OUT = HERE / "reported.json"

# nflverse abbreviations, keyed on the full names the agents were given
TEAMS = {
    "Arizona Cardinals": "ARI", "Atlanta Falcons": "ATL", "Baltimore Ravens": "BAL",
    "Buffalo Bills": "BUF", "Carolina Panthers": "CAR", "Chicago Bears": "CHI",
    "Cincinnati Bengals": "CIN", "Cleveland Browns": "CLE", "Dallas Cowboys": "DAL",
    "Denver Broncos": "DEN", "Detroit Lions": "DET", "Green Bay Packers": "GB",
    "Houston Texans": "HOU", "Indianapolis Colts": "IND", "Jacksonville Jaguars": "JAX",
    "Kansas City Chiefs": "KC", "Las Vegas Raiders": "LV", "Los Angeles Chargers": "LAC",
    "Los Angeles Rams": "LA", "Miami Dolphins": "MIA", "Minnesota Vikings": "MIN",
    "New England Patriots": "NE", "New Orleans Saints": "NO", "New York Giants": "NYG",
    "New York Jets": "NYJ", "Philadelphia Eagles": "PHI", "Pittsburgh Steelers": "PIT",
    "San Francisco 49ers": "SF", "Seattle Seahawks": "SEA", "Tampa Bay Buccaneers": "TB",
    "Tennessee Titans": "TEN", "Washington Commanders": "WAS",
}


def read_agent(path: Path) -> tuple[str | None, dict | None]:
    """(team abbr, structured output) from one agent transcript."""
    prompt, out = "", None
    for line in path.read_text(errors="ignore").splitlines():
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        msg = d.get("message") or {}
        content = msg.get("content")

        # first user turn carries the assignment
        if d.get("type") == "user" and not prompt:
            if isinstance(content, str):
                prompt = content
            elif isinstance(content, list):
                prompt = " ".join(c.get("text", "") for c in content
                                  if isinstance(c, dict) and c.get("type") == "text")

        # last StructuredOutput call wins (agents may retry on schema failure)
        if d.get("type") == "assistant" and isinstance(content, list):
            for c in content:
                if (isinstance(c, dict) and c.get("type") == "tool_use"
                        and "StructuredOutput" in str(c.get("name"))):
                    out = c.get("input")

    team = None
    for full, abbr in TEAMS.items():
        if full in prompt or (out and full in str(out.get("team", ""))):
            team = abbr
            break
    if team is None and out:
        # a few agents name the team as "Chicago Bears (CHI)"
        m = re.search(r"\(([A-Z]{2,3})\)", str(out.get("team", "")))
        if m and m.group(1) in TEAMS.values():
            team = m.group(1)
    return team, out


def harvest() -> dict[str, dict]:
    """Collect every finished agent, dropping the ones that failed.

    A DROPPED TEAM IS NOT A SETTLED TEAM. This run exhausted the session's
    WebSearch budget partway through (200/200), and every agent after that
    point returned `battles: []` -- correctly refusing to invent coverage
    it could not verify. Kept in the file, those empties would be
    indistinguishable from a roster with no camp battles, and every
    computed slot on those teams would score as "nobody is covering this"
    when the truth is that nobody looked.

    So a zero-battle result is discarded rather than recorded. Downstream,
    a team absent from reported.json is excluded from the cross-reference
    entirely instead of counting as evidence of absence.
    """
    if not TRANSCRIPTS.exists():
        raise SystemExit(f"no transcripts at {TRANSCRIPTS}")

    found: dict[str, dict] = {}
    unknown, failed = 0, []
    for f in sorted(TRANSCRIPTS.glob("agent-*.jsonl")):
        team, out = read_agent(f)
        if not out:
            continue
        if not team:
            unknown += 1
            continue
        if not out.get("battles"):
            failed.append(team)
            continue
        # an agent may be retried; keep whichever result found more
        prior = found.get(team)
        if prior and len(prior["battles"]) >= len(out["battles"]):
            continue
        out["_agent"] = f.stem
        found[team] = out

    failed = sorted(set(failed) - set(found))
    missing = sorted(set(TEAMS.values()) - set(found) - set(failed))
    print(f"harvested {len(found)}/32 teams"
          + (f", {unknown} unattributable" if unknown else ""))
    if failed:
        print(f"research FAILED (dropped, not 'no battles'): {' '.join(failed)}")
    if missing:
        print(f"not yet returned: {' '.join(missing)}")
    return found


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--watch", action="store_true", help="report progress, write nothing")
    a = ap.parse_args()

    data = harvest()
    n_b = sum(len(v.get("battles", [])) for v in data.values())
    print(f"{n_b} reported battles across {len(data)} teams")

    if not a.watch:
        OUT.write_text(json.dumps(data, indent=1))
        print(f"wrote {OUT.name} ({OUT.stat().st_size // 1024} KB)")
