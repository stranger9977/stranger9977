"""Assemble everything the artifact needs into one JSON payload.

Four sources, joined on team:

  battles     true_battles.parquet  -- computed contested slots
  coverage    crossref.parquet      -- whether anyone wrote about them
  color       reported.json         -- the beat-writer / analyst context
  drift       drift.parquet         -- this week's z-scored movers

    python payload.py    ->  camp.json

TEAMS WITH NO RESEARCH ARE MARKED, NOT DROPPED. A team whose agent hit
the search-budget wall has real computed battles and no coverage data.
Rendering it as "no battles covered" would be a lie of omission, so it
carries `researched: false` and the artifact greys it out instead of
scoring it.
"""

from __future__ import annotations

import json
import warnings
from pathlib import Path

import pandas as pd

warnings.filterwarnings("ignore")

HERE = Path(__file__).parent
OUT = HERE / "camp.json"

# abbr: (name, camp site, lat, lon, primary colour)
# Coordinates are the training camp site, not the stadium -- Dallas camps
# in Oxnard, KC in St. Joseph, Pittsburgh in Latrobe.
META = {
    "ARI": ("Cardinals", "Tempe, AZ", 33.43, -111.94, "#97233F"),
    "ATL": ("Falcons", "Flowery Branch, GA", 34.18, -83.92, "#A71930"),
    "BAL": ("Ravens", "Owings Mills, MD", 39.42, -76.78, "#241773"),
    "BUF": ("Bills", "Orchard Park, NY", 42.77, -78.79, "#00338D"),
    "CAR": ("Panthers", "Charlotte, NC", 35.23, -80.85, "#0085CA"),
    "CHI": ("Bears", "Lake Forest, IL", 42.24, -87.84, "#0B162A"),
    "CIN": ("Bengals", "Cincinnati, OH", 39.10, -84.52, "#FB4F14"),
    "CLE": ("Browns", "Berea, OH", 41.37, -81.85, "#FF3C00"),
    "DAL": ("Cowboys", "Oxnard, CA", 34.20, -119.18, "#003594"),
    "DEN": ("Broncos", "Englewood, CO", 39.65, -104.99, "#FB4F14"),
    "DET": ("Lions", "Allen Park, MI", 42.26, -83.21, "#0076B6"),
    "GB": ("Packers", "Green Bay, WI", 44.50, -88.06, "#FFB612"),
    "HOU": ("Texans", "Houston, TX", 29.68, -95.41, "#03A0F0"),
    "IND": ("Colts", "Westfield, IN", 40.04, -86.13, "#002C5F"),
    "JAX": ("Jaguars", "Jacksonville, FL", 30.32, -81.64, "#9F792C"),
    "KC": ("Chiefs", "St. Joseph, MO", 39.77, -94.85, "#E31837"),
    "LV": ("Raiders", "Henderson, NV", 36.03, -115.04, "#A5ACAF"),
    "LAC": ("Chargers", "El Segundo, CA", 33.92, -118.41, "#0080C6"),
    "LA": ("Rams", "Thousand Oaks, CA", 34.19, -118.87, "#FFD100"),
    "MIA": ("Dolphins", "Miami Gardens, FL", 25.96, -80.24, "#008E97"),
    "MIN": ("Vikings", "Eagan, MN", 44.81, -93.17, "#4F2683"),
    "NE": ("Patriots", "Foxborough, MA", 42.09, -71.26, "#C60C30"),
    "NO": ("Saints", "Metairie, LA", 30.00, -90.18, "#D3BC8D"),
    "NYG": ("Giants", "East Rutherford, NJ", 40.81, -74.07, "#0B2265"),
    "NYJ": ("Jets", "Florham Park, NJ", 40.78, -74.39, "#125740"),
    "PHI": ("Eagles", "Philadelphia, PA", 39.90, -75.18, "#004C54"),
    "PIT": ("Steelers", "Latrobe, PA", 40.32, -79.38, "#FFB612"),
    "SF": ("49ers", "Santa Clara, CA", 37.40, -121.97, "#AA0000"),
    "SEA": ("Seahawks", "Renton, WA", 47.49, -122.19, "#69BE28"),
    "TB": ("Buccaneers", "Tampa, FL", 27.98, -82.51, "#D50A0A"),
    "TEN": ("Titans", "Nashville, TN", 36.16, -86.77, "#4B92DB"),
    "WAS": ("Commanders", "Ashburn, VA", 39.03, -77.49, "#5A1414"),
}

POS_NAME = {"QB": "Quarterback", "RB": "Running back", "WR": "Receiver",
            "TE": "Tight end", "PK": "Kicker", "KR": "Kick returner",
            "PR": "Punt returner", "NB": "Nickel", "LG": "Left guard",
            "RG": "Right guard", "LT": "Left tackle", "RT": "Right tackle",
            "C": "Center", "FB": "Fullback", "P": "Punter"}


def label(pos: str, rank: int) -> str:
    return f"{POS_NAME.get(pos, pos)} {int(rank)}"


def build() -> dict:
    cross = pd.read_parquet(HERE / "crossref.parquet")
    allb = pd.read_parquet(HERE / "true_battles.parquet")
    reported = json.loads((HERE / "reported.json").read_text())
    researched = set(reported)

    # `rank` collides with DataFrame.rank, so itertuples would need a
    # positional index. Merge instead -- clearer and it keeps the join
    # explicit about which side is authoritative.
    keys = ["team", "pos", "rank"]
    ctx = cross[keys + ["shared", "why", "stakes", "money", "realness", "r_pos"]]
    df = allb.merge(ctx, on=keys, how="left")
    df["covered"] = df.shared.fillna(0) > 0

    battles: dict[str, list] = {t: [] for t in META}
    for row in df.to_dict("records"):
        cov = bool(row["covered"])
        battles.setdefault(row["team"], []).append({
            "slot": label(row["pos"], row["rank"]),
            "pos": row["pos"],
            "rank": int(row["rank"]),
            "flips": int(row["flips"]),
            "contenders": list(row["contenders"]),
            "current": row["current"],
            "fantasy": bool(row["fantasy"]),
            "covered": cov,
            "why": row["why"] if cov else None,
            "stakes": row["stakes"] if cov else None,
            "money": row["money"] if cov else None,
            "realness": row["realness"] if cov else None,
            "reportedAs": row["r_pos"] if cov else None,
        })

    teams = {}
    for abbr, (name, camp, lat, lon, col) in META.items():
        b = sorted(battles.get(abbr, []),
                   key=lambda x: (-x["fantasy"], -x["flips"], x["rank"]))
        rep = reported.get(abbr, {})
        teams[abbr] = {
            "name": name, "camp": camp, "lat": lat, "lon": lon, "color": col,
            "researched": abbr in researched,
            "campOpens": rep.get("campOpens"),
            "biggestUnknown": rep.get("biggestUnknown"),
            "battles": b,
            "n": len(b),
            "nFantasy": sum(x["fantasy"] for x in b),
            "nCovered": sum(x["covered"] for x in b),
        }

    # Drift over six weeks, not one.
    #
    # Camp opens today, so a week-over-week window covers the quietest
    # stretch of the calendar and surfaces nothing but bottom-of-roster
    # shuffling. Six weeks spans the period where teams actually reshaped
    # the chart. Once camp is running the window should tighten -- that is
    # the point of the daily loop.
    import drift as drift_mod

    hist = pd.read_parquet(HERE / "history.parquet")
    d = drift_mod.fantasy_only(drift_mod.drift(hist, weeks=6))
    d = d[d.z.notna() & (d.move != 0)].sort_values("z", key=abs, ascending=False)
    movers = [{"team": r.team, "pos": r.pos, "player": r.player,
               "was": round(float(r.was), 1), "now": round(float(r.now), 1),
               "z": float(r.z)} for r in d.head(40).itertuples()]

    return {
        "teams": teams,
        "movers": movers,
        "window": str(d.window.iloc[0]) if len(d) else None,
        "researchedCount": len(researched),
        "totals": {
            "battles": int(sum(t["n"] for t in teams.values())),
            "fantasy": int(sum(t["nFantasy"] for t in teams.values())),
            "covered": int(sum(t["nCovered"] for t in teams.values())),
        },
    }


if __name__ == "__main__":
    p = build()
    OUT.write_text(json.dumps(p, separators=(",", ":"), default=str))
    t = p["totals"]
    print(f"{t['battles']} battles, {t['fantasy']} fantasy-relevant, "
          f"{t['covered']} with beat coverage")
    print(f"{p['researchedCount']}/32 teams researched, {len(p['movers'])} movers")
    print(f"wrote {OUT.name} ({OUT.stat().st_size // 1024} KB)")
