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
import ast
import json
import re
import unicodedata
import warnings
from pathlib import Path

import pandas as pd

warnings.filterwarnings("ignore")
pd.set_option("display.width", 220)

HERE = Path(__file__).parent
HISTORY = HERE / "history.parquet"


NAME_SUFFIX = re.compile(r"\b(jr|sr|ii|iii|iv|v)\b")


def name_key(name: str) -> str:
    """Fallback identity for sources with no player id.

    Strips the things that differ between two typists rather than between
    two people: punctuation, accents, generational suffixes. Does not fix
    nicknames -- "Cam Ross" and "Cameron Ross" stay distinct here, which
    is why gsis_id is preferred wherever it exists.
    """
    n = unicodedata.normalize("NFKD", str(name)).encode("ascii", "ignore").decode()
    n = n.lower().replace(".", " ").replace("'", "").replace("-", " ")
    n = NAME_SUFFIX.sub(" ", n)
    return " ".join(n.split())


def classify(hist: pd.DataFrame, source: str = "espn",
             since: str | None = None) -> pd.DataFrame:
    """Label every slot change as competition, arrival, or departure.

    IDENTITY IS `pid`, NOT `player`. A depth chart rewrites names between
    snapshots -- suffixes appear, punctuation drops, nicknames formalise --
    and comparing name strings turns each of those into a departure plus an
    arrival. Compare ids; carry names only for display.
    """
    h = hist[hist.source == source].copy()
    if since:
        h = h[h.day >= pd.Timestamp(since)]
    h = h.sort_values(["team", "pos", "rank", "day"])

    # gsis_id where the source has one, normalised name where it does not
    if "pid" in h.columns:
        h["key"] = h.pid.where(h.pid.notna() & (h.pid != ""),
                               h.player.map(name_key))
    else:
        h["key"] = h.player.map(name_key)

    # who was on each team's chart, each day
    on_team = (h.groupby(["team", "day"])["key"]
               .apply(lambda s: frozenset(s.dropna()))
               .rename("roster").reset_index())
    prev = on_team.copy()
    prev["day"] = prev.day + pd.Timedelta(days=1)
    prev = prev.rename(columns={"roster": "roster_prev"})

    grp = h.groupby(["team", "pos", "rank"])
    h["prev_key"] = grp["key"].shift()
    h["prev_player"] = grp["player"].shift()
    ch = h[h.prev_key.notna() & (h.key != h.prev_key)].copy()

    ch = ch.merge(on_team, on=["team", "day"], how="left")
    ch = ch.merge(prev, on=["team", "day"], how="left")
    ch["roster"] = ch.roster.apply(lambda s: s if isinstance(s, frozenset) else frozenset())
    ch["roster_prev"] = ch.roster_prev.apply(lambda s: s if isinstance(s, frozenset) else frozenset())

    ch["out_stayed"] = [p in r for p, r in zip(ch.prev_key, ch.roster)]
    ch["in_was_here"] = [p in r for p, r in zip(ch.key, ch.roster_prev)]

    ch["kind"] = "competition"
    ch.loc[~ch.out_stayed, "kind"] = "departure"
    ch.loc[ch.out_stayed & ~ch.in_was_here, "kind"] = "arrival"

    return ch[["day", "team", "pos", "rank", "prev_player", "player", "kind"]] \
        .rename(columns={"prev_player": "lost_by", "player": "won_by"})


def as_list(v) -> list[str]:
    """Coerce a contenders cell back to a list of names.

    Parquet round-trips of object columns are not reliably typed, and a
    list that comes back as the string '["A","B"]' iterates as characters
    rather than raising -- which turns a name join into a silent zero.
    Every reader of true_battles.parquet should go through here.
    """
    if isinstance(v, str):
        try:
            out = json.loads(v)
        except json.JSONDecodeError:
            try:
                out = ast.literal_eval(v)
            except (ValueError, SyntaxError):
                return [v]
        return [str(x) for x in out] if isinstance(out, list) else [str(out)]
    if v is None:
        return []
    return [str(x) for x in v]


FANTASY_POS = {"QB", "RB", "WR", "TE", "PK", "KR", "PR"}
FANTASY_DEPTH = {"QB": 2, "RB": 3, "WR": 5, "TE": 2, "PK": 1, "KR": 1, "PR": 1}


def is_fantasy(pos: str, rank: int) -> bool:
    return pos in FANTASY_POS and rank <= FANTASY_DEPTH.get(pos, 0)


def battles(ch: pd.DataFrame) -> pd.DataFrame:
    """Competition only, aggregated per slot, with a fantasy flag.

    `contenders` must be the union of both sides. Aggregating winners
    alone loses the displaced player entirely -- a slot that flipped once
    would report a single name, which reads as nobody having competed for
    it and makes the slot unjoinable against any outside source that
    names both men.
    """
    c = ch[ch.kind == "competition"]
    if c.empty:
        return c

    def both_sides(g: pd.DataFrame) -> list[str]:
        seq = []
        for lost, won in zip(g.lost_by, g.won_by):
            seq += [lost, won]
        return list(dict.fromkeys(x for x in seq if isinstance(x, str)))

    # Build column-wise, not as a list of Series.
    #
    # groupby().apply(lambda d: pd.Series({...})) returns an all-object frame
    # because each row mixes int, list, str and Timestamp. pyarrow then can
    # not infer a list type for `contenders` and serialises it as a JSON
    # string, so the next reader gets '["A","B"]' and iterating it yields
    # characters. Nothing raises -- the name join simply matches nothing.
    rows = {"team": [], "pos": [], "rank": [], "flips": [], "contenders": [],
            "current": [], "displaced": [], "last_flip": []}
    for (team, pos, rank), d in c.groupby(["team", "pos", "rank"]):
        rows["team"].append(team)
        rows["pos"].append(pos)
        rows["rank"].append(int(rank))
        rows["flips"].append(len(d))
        rows["contenders"].append(both_sides(d))
        rows["current"].append(d.won_by.iloc[-1])
        rows["displaced"].append(d.lost_by.iloc[0])
        rows["last_flip"].append(d.day.max())
    g = pd.DataFrame(rows)
    g["fantasy"] = [is_fantasy(p, r) for p, r in zip(g.pos, g["rank"])]
    return collapse_swaps(g).sort_values(["flips", "fantasy"], ascending=False)


def collapse_swaps(g: pd.DataFrame) -> pd.DataFrame:
    """One battle per contested group, not one per slot.

    When Ray Davis and Ty Johnson trade places, RB2 and RB3 both record a
    change and the same fight is counted twice. Worse, the two rows
    disagree about who won -- each slot names whoever landed on it. The
    same two men fighting over KR1 and PR1 produces the same duplication
    across different positions entirely.

    So group by (team, set of contenders): one fight, however many slots
    it touched. The battle is named for its highest slot, since that is
    the one with something at stake.
    """
    g = g.copy()
    g["_key"] = [frozenset(c) for c in g.contenders]
    cols = ["team", "pos", "rank", "flips", "contenders", "current",
            "displaced", "last_flip", "fantasy", "slots"]
    out = {c: [] for c in cols}
    for _, grp in g.groupby(["team", "_key"], sort=False):
        top = grp.sort_values(["rank", "flips"], ascending=[True, False]).iloc[0]
        for c in cols:
            if c == "flips":
                out[c].append(int(grp.flips.max()))
            elif c == "fantasy":
                out[c].append(bool(grp.fantasy.any()))
            elif c == "slots":
                out[c].append(sorted({f"{p}{r}" for p, r in zip(grp.pos, grp["rank"])}))
            else:
                out[c].append(top[c])
    return pd.DataFrame(out)


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
    cols = ["team", "pos", "rank", "flips", "contenders", "current", "fantasy"]
    print(b[cols].head(18).to_string(index=False))

    f = b[b.fantasy]
    print(f"\n=== FANTASY-RELEVANT ({len(f)}) ===")
    print(f[["team", "pos", "rank", "flips", "contenders", "current"]].head(15).to_string(index=False))

    print("\n=== biggest transaction churn (NOT battles) ===")
    tx = (ch[ch.kind != "competition"].groupby("team").size()
          .sort_values(ascending=False).head(6))
    print(tx.to_string())
