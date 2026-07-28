"""Where the 2026 rookie class actually sits, and how it got there.

Draft capital says where a team *invested*. The depth chart says where the
rookie is *playing*. The gap between them is the story: a second-rounder
buried at WR6, an undrafted free agent holding a starting slot.

    python rookies.py

JOIN ON gsis_id, NEVER ON NAME. There are two DeVonta Smiths on 2026
rosters -- the Eagles receiver and a rookie Carolina defensive back -- and
a name join silently reports the veteran as a rookie who climbed the depth
chart. Same trap with Justin Jefferson (a Browns linebacker) and Devin
Neal. Six such collisions in this season alone.
"""

from __future__ import annotations

import warnings
from pathlib import Path

import nfl_data_py as nfl
import pandas as pd

warnings.filterwarnings("ignore")
pd.set_option("display.width", 220)

HERE = Path(__file__).parent


# draft_picks uses its own team abbreviations
DRAFT_TEAM = {"LVR": "LV", "KAN": "KC", "GNB": "GB", "SFO": "SF", "TAM": "TB",
              "NWE": "NE", "NOR": "NO", "SDG": "LAC", "LAR": "LA", "RAM": "LA",
              "STL": "LA", "OAK": "LV", "WSH": "WAS", "JAC": "JAX", "ARZ": "ARI",
              "BLT": "BAL", "CLV": "CLE", "HST": "HOU"}


def rookie_ids(season: int = 2026) -> pd.DataFrame:
    """2026 rookies keyed on gsis player_id, with draft capital attached.

    Two traps in the source, both silent:

    1. `draft_picks.gsis_id` does NOT hold gsis ids. It holds PFR-format
       ids ("LOV121782"), while rosters use gsis ("00-0023459"). Merging
       the two matches nothing and every pick comes back UDFA.
    2. draft_picks uses its own team abbreviations (LVR, KAN, GNB).

    So join on pfr_id where both sides have it, and fall back to
    name + normalised team.
    """
    r = nfl.import_seasonal_rosters([season])
    rook = (r[r.years_exp == 0]
            [["player_id", "player_name", "team", "position", "pfr_id"]]
            .dropna(subset=["player_id"])
            .drop_duplicates("player_id"))

    try:
        dp = nfl.import_draft_picks([season])
    except Exception as e:  # noqa: BLE001
        print(f"  draft picks unavailable: {type(e).__name__}")
        rook["round"], rook["pick"] = pd.NA, pd.NA
        rook["capital"] = "UDFA"
        return rook

    dp = dp.rename(columns={"pfr_player_id": "pfr_id", "pfr_player_name": "dname"})
    dp["team"] = dp.team.replace(DRAFT_TEAM)
    dp = dp[["pfr_id", "dname", "team", "round", "pick"]]

    # pass 1 — pfr_id
    a = rook.merge(dp[["pfr_id", "round", "pick"]].dropna(subset=["pfr_id"]),
                   on="pfr_id", how="left")
    # pass 2 — name + team, for rows pass 1 missed
    miss = a["round"].isna()
    if miss.any():
        fb = (a.loc[miss, ["player_id", "player_name", "team"]]
              .merge(dp[["dname", "team", "round", "pick"]],
                     left_on=["player_name", "team"], right_on=["dname", "team"],
                     how="left")
              .set_index("player_id")[["round", "pick"]])
        a = a.set_index("player_id")
        a.update(fb)
        a = a.reset_index()

    matched = a["round"].notna().sum()
    print(f"  draft capital matched for {matched} of {len(dp)} picks")
    a["capital"] = a["round"].apply(lambda x: "UDFA" if pd.isna(x) else f"R{int(x)}")
    return a


def trajectory(rook: pd.DataFrame) -> pd.DataFrame:
    """First / best / current depth-chart rank per rookie, over the archive."""
    d = nfl.import_depth_charts([2026])
    d["dt"] = pd.to_datetime(d["dt"], utc=True).dt.tz_localize(None)
    d["day"] = d.dt.dt.normalize()
    d = d.dropna(subset=["gsis_id", "player_name"])

    rk = d[d.gsis_id.isin(set(rook.player_id))].copy().sort_values("day")

    # a rookie can appear at several slots; keep the one he has held longest
    t = (rk.groupby(["gsis_id", "team", "pos_abb"])
         .agg(first_rank=("pos_rank", "first"), last_rank=("pos_rank", "last"),
              best=("pos_rank", "min"), days=("day", "nunique"))
         .reset_index()
         .sort_values("days", ascending=False)
         .groupby("gsis_id").head(1))

    t = t.merge(rook[["player_id", "player_name", "capital", "round", "pick"]],
                left_on="gsis_id", right_on="player_id", how="left")
    t["move"] = t.first_rank - t.last_rank          # positive = climbed
    return t.astype({"first_rank": int, "last_rank": int, "best": int})


if __name__ == "__main__":
    rook = rookie_ids()
    print(f"2026 rookies on rosters: {len(rook)}  "
          f"(drafted {rook['round'].notna().sum()}, UDFA {rook['round'].isna().sum()})")

    t = trajectory(rook)
    t.to_parquet(HERE / "rookie_traj.parquet")
    print(f"appearing on a depth chart: {len(t)}\n")

    cols = ["player_name", "team", "pos_abb", "capital", "first_rank", "last_rank", "move", "days"]

    print("=== STARTING AS ROOKIES (rank 1 today) ===")
    st = t[t.last_rank == 1].sort_values(["capital", "team"])
    print(f"{len(st)} rookies hold a rank-1 slot\n")
    print(st[cols].head(20).to_string(index=False))

    print("\n=== OUTPERFORMING DRAFT SLOT (day 3 pick or UDFA, now top 2) ===")
    over = t[(t.last_rank <= 2) & (t.capital.isin(["UDFA", "R4", "R5", "R6", "R7"]))]
    print(over.sort_values(["last_rank", "capital"])[cols].head(15).to_string(index=False))

    print("\n=== UNDERPERFORMING DRAFT SLOT (round 1-2, outside top 2) ===")
    under = t[(t.capital.isin(["R1", "R2"])) & (t.last_rank > 2)]
    print(under.sort_values(["capital", "last_rank"], ascending=[True, False])[cols].head(15).to_string(index=False))

    print("\n=== BIGGEST CLIMBERS ===")
    print(t[t.move > 0].sort_values(["move", "last_rank"], ascending=[False, True])[cols].head(10).to_string(index=False))

    print("\n=== BIGGEST FALLERS ===")
    print(t[t.move < 0].sort_values("move")[cols].head(10).to_string(index=False))

    print("\n=== current rank by draft round ===")
    print(t.groupby("capital").agg(n=("last_rank", "size"),
                                   median_rank=("last_rank", "median"),
                                   starters=("last_rank", lambda s: int((s == 1).sum()))
                                   ).to_string())
