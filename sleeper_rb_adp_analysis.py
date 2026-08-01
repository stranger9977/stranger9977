#!/usr/bin/env python3
"""Find which managers in a Sleeper league roster top-12 redraft-ADP running backs.

Usage:
    python sleeper_rb_adp_analysis.py [--username Brochillington] [--league "makeit(dy)nasty"] [--season 2026]

Data sources (no auth required):
  - Sleeper API (https://docs.sleeper.com) for user, leagues, rosters, players
  - Fantasy Football Calculator ADP API for current redraft PPR ADP
"""

import argparse
import json
import re
import sys
import urllib.request

SLEEPER = "https://api.sleeper.app/v1"
FFC_ADP = "https://fantasyfootballcalculator.com/api/v1/adp/ppr?teams=12&year={year}"


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "sleeper-rb-adp-analysis"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def norm(name):
    name = re.sub(r"\b(jr|sr|ii|iii|iv|v)\b\.?", "", name.lower())
    return re.sub(r"[^a-z]", "", name)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--username", default="Brochillington")
    ap.add_argument("--league", default="makeit(dy)nasty")
    ap.add_argument("--season", type=int, default=2026)
    args = ap.parse_args()

    user = get_json(f"{SLEEPER}/user/{args.username}")
    if not user:
        sys.exit(f"Sleeper user {args.username!r} not found")

    leagues = get_json(f"{SLEEPER}/user/{user['user_id']}/leagues/nfl/{args.season}") or []
    if not leagues:
        # League may not be renewed yet for the new season
        leagues = get_json(f"{SLEEPER}/user/{user['user_id']}/leagues/nfl/{args.season - 1}") or []
    target = norm(args.league)
    league = next((l for l in leagues if norm(l["name"]) == target), None)
    if league is None:
        names = ", ".join(l["name"] for l in leagues)
        sys.exit(f"League {args.league!r} not found. Leagues for {args.username}: {names}")

    rosters = get_json(f"{SLEEPER}/league/{league['league_id']}/rosters")
    users = {u["user_id"]: u for u in get_json(f"{SLEEPER}/league/{league['league_id']}/users")}
    players = get_json(f"{SLEEPER}/players/nfl")

    adp = get_json(FFC_ADP.format(year=args.season))["players"]
    top12_rbs = sorted((p for p in adp if p["position"] == "RB"), key=lambda p: p["adp"])[:12]
    adp_by_name = {norm(p["name"]): p for p in top12_rbs}

    print(f"League: {league['name']} ({league['season']})")
    print(f"Top-12 redraft ADP RBs (FFC PPR, 12-team): "
          f"{', '.join(p['name'] for p in top12_rbs)}\n")

    found = set()
    for roster in rosters:
        owner = users.get(roster.get("owner_id"), {})
        manager = owner.get("display_name") or owner.get("username") or "(orphaned team)"
        team = (owner.get("metadata") or {}).get("team_name")
        hits = []
        for pid in roster.get("players") or []:
            p = players.get(pid)
            if p and p.get("position") == "RB":
                match = adp_by_name.get(norm(p.get("full_name") or ""))
                if match:
                    hits.append((match["adp"], p["full_name"]))
                    found.add(norm(p["full_name"]))
        if hits:
            label = f"{manager}" + (f" ({team})" if team else "")
            rbs = ", ".join(f"{name} (ADP {adp_val:.1f})" for adp_val, name in sorted(hits))
            print(f"  {label}: {rbs}")

    missing = [p["name"] for p in top12_rbs if norm(p["name"]) not in found]
    if missing:
        print(f"\nNot rostered in this league (or name mismatch): {', '.join(missing)}")


if __name__ == "__main__":
    main()
