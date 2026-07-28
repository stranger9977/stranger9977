"""Daily tracker: append a snapshot, then measure movement and disagreement.

    python track.py              # snapshot all sources, append to history
    python track.py --no-scrape  # espn only (works anywhere)
    python track.py --report     # print current state, no new snapshot

History is a single append-only parquet keyed on (day, source, team, pos,
rank). Re-running on the same day replaces that day rather than duplicating,
so the loop is idempotent.

Two distinct signals come out of this, and they are not the same thing:

  MOVEMENT      within one source, over time. "ESPN changed its mind."
  DISAGREEMENT  between sources, at one moment. "Nobody is sure."

A slot that is both is the strongest camp-battle signal available without
a beat reporter.
"""

from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

import pandas as pd

import sources

HERE = Path(__file__).parent
HISTORY = HERE / "history.parquet"


# ------------------------------------------------------------- capture
def capture(use_scrapers: bool = True) -> pd.DataFrame:
    snap = sources.snapshot(use_scrapers=use_scrapers)
    snap["day"] = pd.Timestamp(dt.date.today())

    if HISTORY.exists():
        hist = pd.read_parquet(HISTORY)
        # idempotent: today's rows for these sources get replaced
        mask = (hist.day == snap.day.iloc[0]) & (hist.source.isin(snap.source.unique()))
        hist = hist[~mask]
        out = pd.concat([hist, snap], ignore_index=True)
    else:
        out = snap

    out.to_parquet(HISTORY, index=False)
    print(f"history: {len(out)} rows, {out.day.nunique()} days, "
          f"{out.day.min().date()} -> {out.day.max().date()}")
    return out


# ------------------------------------------------------------ movement
def movement(hist: pd.DataFrame, source: str = "espn", since: str | None = None) -> pd.DataFrame:
    """Per (team,pos,rank): how many times the holder changed."""
    h = hist[hist.source == source].copy()
    if since:
        h = h[h.day >= pd.Timestamp(since)]
    h = h.sort_values(["team", "pos", "rank", "day"])
    h["prev"] = h.groupby(["team", "pos", "rank"])["player"].shift()
    h["changed"] = h.prev.notna() & (h.player != h.prev)

    g = h.groupby(["team", "pos", "rank"])
    return (g.agg(changes=("changed", "sum"),
                  holders=("player", "nunique"),
                  current=("player", "last"),
                  days=("day", "nunique"))
            .reset_index()
            .astype({"changes": int, "holders": int}))


# -------------------------------------------------------- disagreement
def disagreement(hist: pd.DataFrame, day: pd.Timestamp | None = None) -> pd.DataFrame:
    """Per (team,pos,rank): do the sources name the same player?

    Only meaningful once at least two sources are present. Returns empty
    with a note if not.
    """
    day = day or hist.day.max()
    d = hist[hist.day == day]
    if d.source.nunique() < 2:
        print(f"disagreement: only {d.source.nunique()} source on {day.date()} "
              f"-- need 2+. Run the scrapers.")
        return pd.DataFrame()

    g = (d.groupby(["team", "pos", "rank"])
         .agg(names=("player", lambda s: sorted(set(s))),
              n_sources=("source", "nunique"))
         .reset_index())
    g["n_names"] = g.names.map(len)
    g["disputed"] = g.n_names > 1
    return g.sort_values(["disputed", "n_names"], ascending=False)


def report(hist: pd.DataFrame) -> None:
    print(f"\ndays tracked: {hist.day.nunique()}  "
          f"({hist.day.min().date()} -> {hist.day.max().date()})")
    print(f"sources: {sorted(hist.source.unique())}")

    mv = movement(hist)
    hot = mv[mv.changes > 0].sort_values("changes", ascending=False)
    print(f"\nslots that moved (espn): {len(hot)}")
    print(hot.head(12).to_string(index=False))

    by_rank = mv.groupby("rank").changes.sum()
    print("\nmovement by depth-chart rank:")
    print(by_rank.head(4).to_string())

    dis = disagreement(hist)
    if len(dis):
        d = dis[dis.disputed]
        print(f"\ncontested between sources: {len(d)} of {len(dis)} slots")
        print(d.head(12).to_string(index=False))


def seed() -> pd.DataFrame:
    """Backfill espn history from nflverse rather than starting at zero.

    nflverse already holds a daily timestamped archive back to 22 Mar 2026,
    so day one of tracking starts with four months of movement behind it.
    Only espn can be seeded -- Ourlads and Rotowire have no public archive,
    which is exactly why they have to be captured going forward.
    """
    import nfl_data_py as nfl

    d = nfl.import_depth_charts([2026])
    d["dt"] = pd.to_datetime(d["dt"], utc=True).dt.tz_localize(None)
    d["day"] = d.dt.dt.normalize()
    d = (d.sort_values("dt")
         .groupby(["team", "pos_abb", "pos_rank", "day"], as_index=False)
         .last())

    hist = pd.DataFrame({
        "source": "espn", "team": d.team, "pos": d.pos_abb,
        "rank": d.pos_rank.astype(int), "player": d.player_name,
        "scraped_at": d.dt.astype(str), "day": d.day,
    }).dropna(subset=["player"])

    if HISTORY.exists():
        old = pd.read_parquet(HISTORY)
        hist = pd.concat([old[old.source != "espn"], hist], ignore_index=True)
    hist.to_parquet(HISTORY, index=False)
    print(f"seeded: {len(hist)} rows, {hist.day.nunique()} days back to "
          f"{hist.day.min().date()}")
    return hist


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-scrape", action="store_true",
                    help="espn only; skip ourlads/rotowire")
    ap.add_argument("--report", action="store_true",
                    help="report on existing history without capturing")
    ap.add_argument("--seed", action="store_true",
                    help="one-time backfill of espn history from nflverse")
    a = ap.parse_args()

    if a.seed:
        report(seed())
    elif a.report:
        if not HISTORY.exists():
            raise SystemExit("no history yet -- run --seed first")
        report(pd.read_parquet(HISTORY))
    else:
        report(capture(use_scrapers=not a.no_scrape))
