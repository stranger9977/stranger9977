"""The roster-flip trade: what NIL and the portal actually changed.

Reproduces every number in ANGLE.md from public mirrors. No API key.

    python rebuild.py --download    # ~11 MB of parquet, one time
    python rebuild.py               # run the analysis

DATA: ESPN rosters and CFBD schedules, mirrored by sportsdataverse.
The mirror URLs come from the package loader source, not guesswork --
the paths documented in cfbfastR-data's README are stale.

IDENTITY IS athlete_id, NEVER NAME. Same lesson as the NFL tracker:
names get respelled between seasons and a string comparison invents
transfers that never happened.

TWO KNOWN BREAKS IN THE SOURCE, both of which shape what is quotable:

  1. ESPN roster coverage jumped in 2019 (median FBS roster 93 -> 114;
     walk-ons appear). Retention computed before/after that break is not
     comparable, so every headline number here starts at 2019. The
     collapse happens 2021 -> 2022, safely inside the stable window.
  2. The 2025 dip is partly the House-settlement roster cap (105) purge.
     Real players really left, but some were cut, not poached. Say so.

The class-of-departure analysis was cut entirely: ESPN's `year` field is
coded inconsistently across seasons (it implies 71% of freshmen left in
2019, which is not a thing that happened). Nothing downstream uses it.
"""

from __future__ import annotations

import argparse
import urllib.request
import warnings
from pathlib import Path

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")
pd.set_option("display.width", 220)

HERE = Path(__file__).parent
DATA = HERE / "data"
YEARS = range(2015, 2026)

ROSTER = ("https://raw.githubusercontent.com/sportsdataverse/cfbfastR-data/"
          "main/rosters/parquet/cfb_rosters_{y}.parquet")
SCHED = ("https://raw.githubusercontent.com/sportsdataverse/cfbfastR-data/"
         "main/schedules/parquet/cfb_schedules_{y}.parquet")


def download() -> None:
    DATA.mkdir(exist_ok=True)
    for y in YEARS:
        for url, name in ((ROSTER, f"rosters_{y}.parquet"),
                          (SCHED, f"sched_{y}.parquet")):
            out = DATA / name
            if out.exists():
                continue
            urllib.request.urlretrieve(url.format(y=y), out)
            print(f"  {name}")


def load() -> tuple[dict, dict]:
    R = {y: pd.read_parquet(DATA / f"rosters_{y}.parquet") for y in YEARS}
    S = {y: pd.read_parquet(DATA / f"sched_{y}.parquet") for y in YEARS}
    return R, S


def fbs_teams(S: dict, y: int) -> set:
    s = S[y]
    return (set(s[s.home_division == "fbs"].home_team)
            | set(s[s.away_division == "fbs"].away_team))


def retention(R: dict, S: dict) -> pd.DataFrame:
    """Share of last season's roster (by athlete_id) still there."""
    rows = []
    for y in range(2016, 2026):
        prev, cur = R[y - 1], R[y]
        for t in fbs_teams(S, y) & set(cur.team) & set(prev.team):
            a0 = set(prev[prev.team == t].athlete_id.dropna())
            a1 = set(cur[cur.team == t].athlete_id.dropna())
            if len(a0) < 40:      # partial roster = junk denominator
                continue
            rows.append((y, t, len(a0 & a1) / len(a0)))
    return pd.DataFrame(rows, columns=["season", "team", "retention"])


def wins(S: dict, y: int) -> pd.DataFrame:
    """FBS teams with a full season played."""
    s = S[y]
    if "completed" in s:
        s = s[s.completed == True]  # noqa: E712
    h = s[["home_team", "home_points", "away_points"]].rename(columns={"home_team": "team"})
    h["win"] = h.home_points > h.away_points
    a = s[["away_team", "away_points", "home_points"]].rename(columns={"away_team": "team"})
    a["win"] = a.away_points > a.home_points
    g = pd.concat([h[["team", "win"]], a[["team", "win"]]]) \
        .groupby("team").agg(w=("win", "sum"), g=("win", "size"))
    return g[(g.g >= 10) & (g.index.isin(fbs_teams(S, y)))]


def swings(S: dict) -> pd.DataFrame:
    """Year-over-year FBS win changes, covid transitions removed.

    2020 seasons were 6-11 games under opt-outs, so both the 2019->2020
    and 2020->2021 deltas measure the pandemic, not team-building.
    """
    W = {y: wins(S, y) for y in YEARS}
    rows = []
    for y in range(2015, 2025):
        if y == 2020:
            continue
        both = W[y].join(W[y + 1], how="inner", lsuffix="0", rsuffix="1")
        for t, r in both.iterrows():
            rows.append((y + 1, t, int(r.w0), int(r.w1), int(r.w1 - r.w0)))
    d = pd.DataFrame(rows, columns=["season", "team", "w0", "w1", "jump"])
    d = d[(d.season <= 2019) | (d.season >= 2022)]
    d["era"] = np.where(d.season >= 2022, "portal", "before")
    return d


def report(ret: pd.DataFrame, d: pd.DataFrame) -> None:
    print("=== median FBS roster retention ===")
    print("(2016-18 rides an ESPN coverage break; quote from 2019 on)")
    print(ret.groupby("season").retention.median().round(3).to_string())

    bad = d[d.w0 <= 4].merge(ret, on=["season", "team"], how="inner")

    print("\n=== the trade: bad teams (<=4 wins), next season, by what they did ===")
    for era, g in bad.groupby("era"):
        g = g.assign(path=pd.qcut(g.retention, 3,
                     labels=["flipped", "middle", "kept"]))
        t = g.groupby("path").agg(n=("jump", "size"),
                                  mean_jump=("jump", "mean"),
                                  reach_9=("w1", lambda s: (s >= 9).mean()))
        print(f"\n{era}:")
        print(t.round(3).to_string())
    print("\nThe mean favors keeping in both eras. The tail flipped sides:")
    print("before, keepers reached 9 wins at 14%, flippers at 7%.")
    print("Portal era: flippers 14%, keepers 7%. Same means, opposite tails.")

    print("\n=== volatility ===")
    print(d.groupby("era").jump.agg(
        mean_abs=lambda s: s.abs().mean(),
        pct_swing5=lambda s: (s.abs() >= 5).mean()).round(3).to_string())

    print("\n=== every 9-win season built on a <=4-win one, portal era ===")
    r = bad[(bad.era == "portal") & (bad.w1 >= 9)].sort_values("retention")
    print(r[["season", "team", "w0", "w1", "retention"]].round(2).to_string(index=False))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--download", action="store_true")
    a = ap.parse_args()
    if a.download or not DATA.exists():
        download()
    R, S = load()
    ret = retention(R, S)
    d = swings(S)
    ret.to_parquet(HERE / "retention.parquet")
    d.to_parquet(HERE / "swings.parquet")
    report(ret, d)
