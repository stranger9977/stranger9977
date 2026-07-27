#!/usr/bin/env python3
"""Check a clip manifest against league footage policy.

Deterministic gate that runs before editing. It cannot tell you whether a clip
earns its place in the video -- that is judgment and stays in SKILL.md -- but it
will refuse to pass a manifest containing sources with a documented strike risk,
and it tallies per-league exposure so a video's risk is a number rather than a
feeling.

Usage:
    python check_clips.py <manifest.yaml> [--budget-json out.json]

Exit codes:
    0  pass, or pass with warnings
    1  blocked -- manifest contains a forbidden source
    2  manifest malformed
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required:  pip install pyyaml")


# Tiers reflect references/league-policy.md. Re-verify before trusting; the UFC
# and NHL entries moved within the last 18 months.
LEAGUE_TIER = {
    "NBA": "permissive",
    "WNBA": "permissive",
    "NFL": "claims",
    "MLB": "claims",
    "NHL": "avoid",
    "UFC": "avoid",
    "SOCCER": "avoid",
    "PREMIER LEAGUE": "avoid",
    "UEFA": "avoid",
    "FIFA": "avoid",
    "F1": "avoid",
    "NCAA": "avoid",
    "CFB": "avoid",
    "NONE": "clean",
}

# Sources that are never acceptable, regardless of league or treatment.
FORBIDDEN_SOURCES = {
    "coaches_film": (
        "College coaching film / All-22 is the only footage category with a "
        "documented strike outcome (XOS/Catapult vs Brett Kollmann, May 2025). "
        "Substitute data viz, licensed stills, or diagrams."
    ),
}

CLEAN_SOURCES = {"original", "licensed_program", "licensed_stock"}
KNOWN_SOURCES = CLEAN_SOURCES | {"broadcast", "league_upload"} | set(FORBIDDEN_SOURCES)


@dataclass
class Finding:
    level: str  # BLOCK | WARN | NOTE
    clip: str
    message: str


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)
    seconds_by_league: dict[str, int] = field(default_factory=dict)
    claimable_seconds: int = 0
    total_seconds: int = 0

    @property
    def blocked(self) -> bool:
        return any(f.level == "BLOCK" for f in self.findings)


def check(manifest: dict) -> Report:
    rep = Report()
    clips = manifest.get("clips")

    if not isinstance(clips, list) or not clips:
        rep.findings.append(Finding("BLOCK", "-", "manifest has no 'clips' list"))
        return rep

    for i, clip in enumerate(clips):
        cid = str(clip.get("id") or f"#{i + 1}")
        source = str(clip.get("source", "")).strip().lower()
        league = str(clip.get("league", "none")).strip().upper()
        duration = clip.get("duration_s", 0) or 0
        audio = str(clip.get("audio", "")).strip().lower()

        if not isinstance(duration, (int, float)) or duration < 0:
            rep.findings.append(Finding("BLOCK", cid, f"invalid duration_s: {duration!r}"))
            continue
        duration = int(duration)
        rep.total_seconds += duration

        if source not in KNOWN_SOURCES:
            rep.findings.append(
                Finding("BLOCK", cid, f"unknown source {source!r}; expected one of "
                                      f"{', '.join(sorted(KNOWN_SOURCES))}")
            )
            continue

        if source in FORBIDDEN_SOURCES:
            rep.findings.append(Finding("BLOCK", cid, FORBIDDEN_SOURCES[source]))
            continue

        if source in CLEAN_SOURCES:
            rep.findings.append(Finding("NOTE", cid, f"{source}: no Content ID exposure"))
            continue

        # Remaining: broadcast or league_upload -- claimable.
        rep.claimable_seconds += duration
        rep.seconds_by_league[league] = rep.seconds_by_league.get(league, 0) + duration

        tier = LEAGUE_TIER.get(league)
        if tier is None:
            rep.findings.append(
                Finding("WARN", cid, f"league {league!r} not in the policy table -- "
                                     f"research it before publishing")
            )
        elif tier == "avoid":
            rep.findings.append(
                Finding("BLOCK", cid, f"{league} is avoid-tier for footage (aggressive "
                                      f"enforcement, documented strike cases). Substitute "
                                      f"stills, diagrams, or animation.")
            )
            continue
        elif tier == "claims":
            rep.findings.append(
                Finding("WARN", cid, f"{league} broadcast: expect a monetize-claim. "
                                     f"Upload unlisted first. Do not dispute a "
                                     f"monetize-claim from {league}.")
            )

        if audio != "muted":
            rep.findings.append(
                Finding("WARN", cid, "broadcast audio not muted -- this invites a separate "
                                     "music-industry claim on top of the league claim")
            )

    if rep.claimable_seconds and rep.total_seconds:
        pct = 100 * rep.claimable_seconds / rep.total_seconds
        if pct > 25:
            rep.findings.append(
                Finding("WARN", "-", f"{pct:.0f}% of runtime is claimable footage. The "
                                     f"charts should carry the argument; footage "
                                     f"illustrates. High ratios also raise YPP "
                                     f"reused-content exposure.")
            )
    return rep


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("manifest", type=Path)
    ap.add_argument("--budget-json", type=Path, help="write the tally as JSON")
    args = ap.parse_args()

    try:
        manifest = yaml.safe_load(args.manifest.read_text())
    except FileNotFoundError:
        print(f"no such manifest: {args.manifest}", file=sys.stderr)
        return 2
    except yaml.YAMLError as exc:
        print(f"malformed YAML: {exc}", file=sys.stderr)
        return 2

    if not isinstance(manifest, dict):
        print("manifest must be a YAML mapping", file=sys.stderr)
        return 2

    rep = check(manifest)

    icon = {"BLOCK": "BLOCK", "WARN": " WARN", "NOTE": " note"}
    for f in rep.findings:
        print(f"{icon[f.level]}  [{f.clip}]  {f.message}")

    print()
    print(f"runtime         {rep.total_seconds}s")
    print(f"claimable       {rep.claimable_seconds}s")
    for league, secs in sorted(rep.seconds_by_league.items()):
        print(f"  {league:<12}  {secs}s  ({LEAGUE_TIER.get(league, 'unknown')})")

    if args.budget_json:
        args.budget_json.write_text(json.dumps({
            "total_seconds": rep.total_seconds,
            "claimable_seconds": rep.claimable_seconds,
            "seconds_by_league": rep.seconds_by_league,
            "blocked": rep.blocked,
        }, indent=2))

    print()
    if rep.blocked:
        print("BLOCKED -- fix the findings above before editing.")
        return 1
    print("PASS -- upload unlisted first to surface any Content ID matches.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
