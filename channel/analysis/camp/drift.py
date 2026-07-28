"""Week-over-week drift in depth-chart position, z-scored within position.

Raw rank changes are not comparable across positions. Moving from WR6 to
WR4 is routine -- teams list a dozen receivers. Moving from QB2 to QB1 is
the whole story. So every change is z-scored against the distribution of
changes at that position group, and the z is what gets ranked.

Consensus across sources is computed the same way: mean rank across
whichever sources are present, with the spread between them as a separate
uncertainty signal. With one source the mean is that source and the spread
is zero -- structurally correct, just uninformative until the scrapers run.

    python drift.py                 # last week's movers
    python drift.py --weeks 4       # 4-week window
    python drift.py --fantasy       # skill positions only
"""

from __future__ import annotations

import argparse
import warnings
from pathlib import Path

import pandas as pd

warnings.filterwarnings("ignore")
pd.set_option("display.width", 220)

HERE = Path(__file__).parent
HISTORY = HERE / "history.parquet"

# Slots a fantasy manager actually cares about, and how deep it matters.
FANTASY = {"QB": 2, "RB": 3, "WR": 5, "TE": 2, "PK": 1, "KR": 1, "PR": 1}


def consensus(hist: pd.DataFrame) -> pd.DataFrame:
    """Mean rank per player-slot per day, across whatever sources exist."""
    g = (hist.groupby(["day", "team", "pos", "player"])
         .agg(rank=("rank", "mean"),
              spread=("rank", lambda s: s.max() - s.min()),
              n_src=("source", "nunique"))
         .reset_index())
    return g


def weekly(cons: pd.DataFrame) -> pd.DataFrame:
    """Collapse to one mean rank per player-slot per ISO week."""
    c = cons.copy()
    c["week"] = c.day.dt.to_period("W").dt.start_time
    return (c.groupby(["week", "team", "pos", "player"])
            .agg(rank=("rank", "mean"), spread=("spread", "max"),
                 n_src=("n_src", "max"))
            .reset_index())


def drift(hist: pd.DataFrame, weeks: int = 2) -> pd.DataFrame:
    """Change in mean rank between the last two weeks, z-scored by position."""
    wk = weekly(consensus(hist))
    keep = sorted(wk.week.unique())[-weeks:]
    if len(keep) < 2:
        raise SystemExit(f"need 2+ weeks of history, have {len(keep)}. "
                         "Run track.py --seed, or wait a week.")
    first, last = keep[0], keep[-1]

    a = wk[wk.week == first][["team", "pos", "player", "rank"]].rename(columns={"rank": "was"})
    b = wk[wk.week == last][["team", "pos", "player", "rank", "spread", "n_src"]].rename(columns={"rank": "now"})
    d = b.merge(a, on=["team", "pos", "player"], how="outer")

    # entering / leaving the chart are real events, not missing data
    d["status"] = "held"
    d.loc[d.was.isna() & d.now.notna(), "status"] = "added"
    d.loc[d.now.isna() & d.was.notna(), "status"] = "dropped"
    d["move"] = d.was - d.now                      # positive = climbed

    # Z-score against the players who ACTUALLY MOVED, not against everyone.
    #
    # In any given week ~97% of slots are unchanged. Standardising against
    # that distribution puts a near-zero std in the denominator, so every
    # move scores +-10 and z becomes a monotone restatement of raw rank
    # change -- it stops distinguishing anything and it hands the top of
    # the leaderboard to whichever WR shuffled between 9th and 12th.
    #
    # Conditioning on movement asks the question worth asking: given that
    # this slot moved at all, is this a normal-sized move for the position
    # or an unusual one? A WR sliding two spots is ordinary; a QB moving
    # two spots is the season.
    m = d[(d.status == "held") & (d.move != 0)]
    stats = m.groupby("pos")["move"].agg(["mean", "std", "size"])
    stats = stats[stats["size"] >= 3]        # std of two points is not a scale
    d = d.merge(stats.drop(columns="size"), on="pos", how="left")
    # .where rather than .replace(0, NA) -- the latter recurses in pandas 2.x
    sd = d["std"].where(d["std"] > 0)
    d["z"] = ((d["move"] - d["mean"]) / sd).round(2)
    d.loc[d.move == 0, "z"] = pd.NA

    d["window"] = f"{pd.Timestamp(first).date()} -> {pd.Timestamp(last).date()}"
    return d.drop(columns=["mean", "std"])


def fantasy_only(d: pd.DataFrame) -> pd.DataFrame:
    """Skill slots, at depths a fantasy manager would notice."""
    keep = []
    for pos, depth in FANTASY.items():
        sub = d[(d.pos == pos) & ((d.now <= depth) | (d.was <= depth))]
        keep.append(sub)
    return pd.concat(keep) if keep else d.iloc[:0]


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--weeks", type=int, default=2)
    ap.add_argument("--fantasy", action="store_true")
    a = ap.parse_args()

    if not HISTORY.exists():
        raise SystemExit("no history -- run:  python track.py --seed")

    hist = pd.read_parquet(HISTORY)
    d = drift(hist, a.weeks)
    print(f"window: {d.window.iloc[0]}   sources: {sorted(hist.source.unique())}")
    if hist.source.nunique() < 2:
        print("NOTE: one source, so `spread` is 0 everywhere. "
              "Cross-source disagreement needs the scrapers.\n")

    if a.fantasy:
        d = fantasy_only(d)
        print(f"--- fantasy-relevant slots only ---\n")

    cols = ["team", "pos", "player", "was", "now", "move", "z", "status", "spread"]
    moved = d[(d.status != "held") | (d.move.abs() > 0)]
    print(f"{len(moved)} slots moved of {len(d)} tracked\n")

    print("=== CLIMBED (by z within position) ===")
    print(moved[moved.move > 0].sort_values("z", ascending=False)[cols].head(15).to_string(index=False))
    print("\n=== FELL ===")
    print(moved[moved.move < 0].sort_values("z")[cols].head(12).to_string(index=False))
    print("\n=== NEW TO THE CHART ===")
    print(moved[moved.status == "added"][["team", "pos", "player", "now"]].head(12).to_string(index=False))

    out = HERE / ("drift_fantasy.parquet" if a.fantasy else "drift.parquet")
    d.to_parquet(out)
    print(f"\nwrote {out.name}")
