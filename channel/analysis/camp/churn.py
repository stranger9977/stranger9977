"""When does an NFL depth chart actually move?

Uses nflreadr/ESPN timestamped depth charts. The 2025 file covers Aug 2025 ->
Mar 2026; the 2026 file covers Mar 2026 -> present. Together they tile a full
annual cycle.

A "change" = the rank-1 player at a (team, position slot) differs from the
previous daily snapshot. 881 starting slots league-wide.

    python churn.py
"""
import warnings
import pandas as pd
import nfl_data_py as nfl

warnings.filterwarnings("ignore")


def load(years=(2025, 2026)):
    out = []
    for y in years:
        d = nfl.import_depth_charts([y])
        d["dt"] = pd.to_datetime(d["dt"], utc=True).dt.tz_localize(None)
        d["d"] = d.dt.dt.normalize()
        out.append(d[d.pos_rank == 1])
    return pd.concat(out)


def daily_starters(starters):
    """One row per (team, slot, day): who held the job that day."""
    d = (starters.sort_values("dt")
         .groupby(["team", "pos_abb", "d"])["player_name"].last()
         .reset_index()
         .sort_values(["team", "pos_abb", "d"]))
    d["prev"] = d.groupby(["team", "pos_abb"])["player_name"].shift()
    d["changed"] = d.prev.notna() & (d.player_name != d.prev)
    return d


if __name__ == "__main__":
    daily = daily_starters(load())
    daily.to_parquet("annual_starters.parquet")

    by_month = daily.groupby(pd.Grouper(key="d", freq="M"))["changed"].sum()
    print(by_month[by_month.index >= "2025-08-01"].astype(int).to_string())

    since_jun = daily[daily.d >= "2026-06-01"].groupby(["team", "pos_abb"])["changed"].sum()
    print(f"\nfrozen since Jun 1: {(since_jun == 0).sum()} of {len(since_jun)} slots "
          f"({(since_jun == 0).mean():.1%})")
