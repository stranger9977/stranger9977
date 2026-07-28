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
    if not TRANSCRIPTS.exists():
        raise SystemExit(f"no transcripts at {TRANSCRIPTS}")

    found: dict[str, dict] = {}
    unknown = 0
    for f in sorted(TRANSCRIPTS.glob("agent-*.jsonl")):
        team, out = read_agent(f)
        if not out:
            continue
        if not team:
            unknown += 1
            continue
        # an agent may be retried; keep whichever result has more battles
        prior = found.get(team)
        if prior and len(prior.get("battles", [])) >= len(out.get("battles", [])):
            continue
        out["_agent"] = f.stem
        found[team] = out

    missing = sorted(set(TEAMS.values()) - set(found))
    print(f"harvested {len(found)}/32 teams"
          + (f", {unknown} unattributable" if unknown else ""))
    if missing:
        print(f"still missing: {' '.join(missing)}")
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
