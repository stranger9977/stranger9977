"""Separate camp battles from roster transactions.

THE BUG THIS FIXES: raw depth-chart churn counts every change equally. When
Jared Verse is traded to Cleveland and appears alongside Myles Garrett, the
chart moves -- but nobody beat anybody out. That is a transaction. Counting
it as a camp battle inflates every team that was active in free agency and
makes the metric mostly a trade tracker.

The distinction is computable. For a change A -> B at some slot on day D:

    A still on this team's chart on D?   B on this team's chart on D-1?
    ---------------------------------------------------------------
    yes                                  yes        COMPETITION
    no                                   --         DEPARTURE   (A left)
    --                                   no         ARRIVAL     (B joined)

Only COMPETITION is a camp battle: two players who were both already on the
roster, and one passed the other. Everything else is the transaction wire.

    python battles.py
    python battles.py --since 2026-06-01
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


def classify(hist: pd.DataFrame, source: str = "espn",
             since: str | None = None) -> pd.DataFrame:
    """Label every slot change as competition, arrival, or departure."""
    h = hist[hist.source == source].copy()
    if since:
        h = h[h.day >= pd.Timestamp(since)]
    h = h.sort_values(["team", "pos", "rank", "day"])

    # who was on each team's chart, each day
    on_team = (h.groupby(["team", "day"])["player"]
               .apply(lambda s: frozenset(s.dropna()))
               .rename("roster").reset_index())
    prev = on_team.copy()
    prev["day"] = prev.day + pd.Timedelta(days=1)
    prev = prev.rename(columns={"roster": "roster_prev"})

    h["prev_player"] = h.groupby(["team", "pos", "rank"])["player"].shift()
    ch = h[h.prev_player.notna() & (h.player != h.prev_player)].copy()

    ch = ch.merge(on_team, on=["team", "day"], how="left")
    ch = ch.merge(prev, on=["team", "day"], how="left")
    ch["roster"] = ch.roster.apply(lambda s: s if isinstance(s, frozenset) else frozenset())
    ch["roster_prev"] = ch.roster_prev.apply(lambda s: s if isinstance(s, frozenset) else frozenset())

    ch["out_stayed"] = [p in r for p, r in zip(ch.prev_player, ch.roster)]
    ch["in_was_here"] = [p in r for p, r in zip(ch.player, ch.roster_prev)]

    ch["kind"] = "competition"
    ch.loc[~ch.out_stayed, "kind"] = "departure"
    ch.loc[ch.out_stayed & ~ch.in_was_here, "kind"] = "arrival"

    return ch[["day", "team", "pos", "rank", "prev_player", "player", "kind"]] \
        .rename(columns={"prev_player": "lost_by", "player": "won_by"})


FANTASY_POS = {"QB", "RB", "WR", "TE", "PK", "KR", "PR"}
FANTASY_DEPTH = {"QB": 2, "RB": 3, "WR": 5, "TE": 2, "PK": 1, "KR": 1, "PR": 1}


def is_fantasy(pos: str, rank: int) -> bool:
    return pos in FANTASY_POS and rank <= FANTASY_DEPTH.get(pos, 0)


def battles(ch: pd.DataFrame) -> pd.DataFrame:
    """Competition only, aggregated per slot, with a fantasy flag."""
    c = ch[ch.kind == "competition"]
    if c.empty:
        return c
    g = (c.groupby(["team", "pos", "rank"])
         .agg(flips=("won_by", "size"),
              holders=("won_by", lambda s: list(dict.fromkeys(s))),
              current=("won_by", "last"),
              last_flip=("day", "max"))
         .reset_index())
    g["fantasy"] = [is_fantasy(p, r) for p, r in zip(g.pos, g["rank"])]
    return g.sort_values(["flips", "fantasy"], ascending=False)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--since", default="2026-05-01")
    a = ap.parse_args()

    if not HISTORY.exists():
        raise SystemExit("no history -- run:  python track.py --seed")

    ch = classify(pd.read_parquet(HISTORY), since=a.since)
    n = len(ch)
    mix = ch.kind.value_counts()
    print(f"=== {n} depth-chart changes since {a.since} ===")
    for k, v in mix.items():
        print(f"  {k:<12} {v:>5}   {v/n:>5.1%}")
    print(f"\nSo {mix.get('competition',0)/n:.0%} of raw churn is actual competition. "
          f"The rest is the transaction wire.")

    b = battles(ch)
    b.to_parquet(HERE / "true_battles.parquet")
    print(f"\n=== TRUE CAMP BATTLES: {len(b)} contested slots ===")
    cols = ["team", "pos", "rank", "flips", "current", "fantasy"]
    print(b[cols].head(18).to_string(index=False))

    f = b[b.fantasy]
    print(f"\n=== FANTASY-RELEVANT ({len(f)}) ===")
    print(f[["team", "pos", "rank", "flips", "holders", "current"]].head(15).to_string(index=False))

    print("\n=== biggest transaction churn (NOT battles) ===")
    tx = (ch[ch.kind != "competition"].groupby("team").size()
          .sort_values(ascending=False).head(6))
    print(tx.to_string())
