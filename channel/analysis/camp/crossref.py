"""Cross the computed camp battles against the reported ones.

Two independent views of the same thing:

  COMPUTED   true_battles.parquet -- slots where the depth chart actually
             changed hands between two players who were both already on
             the roster. No human judgement, no beat access, no narrative.

  REPORTED   reported.json -- what 32 research agents found beat writers
             and fantasy analysts actually writing about.

Crossing them produces three buckets, and the interesting one is not the
overlap:

  BOTH        a battle the data sees and the media covers. Validated.
  DATA ONLY   the chart keeps flipping and nobody has written a word.
              This is the sharpest thing in the file -- it is a story
              that exists and has not been told.
  MEDIA ONLY  covered, chart never moved.

DO NOT READ "MEDIA ONLY" AS "MANUFACTURED". The two buckets are not
equally trustworthy, and the asymmetry is structural.

DATA ONLY is safe. If the chart moved, the slot demonstrably exists and
something demonstrably happened at it. Absence of coverage is then a real
absence.

MEDIA ONLY is not safe, because a battle can be entirely genuine and
still be invisible to the chart -- the chart has no row for it. ESPN
lists DE, DT, LB, CB, S. It has no nickel slot, no rotational-edge slot,
no third-safety slot. `side_of_ball()` measures exactly this: 70% of
covered defensive battles never register, against 25% of offensive-line
battles. That gradient is chart resolution, not media invention.

So the defensible claim runs one way only: there are real competitions
nobody is covering. The reverse claim needs a source that can see
defensive sub-packages, which a public depth chart cannot.

THE JOIN IS ON PLAYER NAMES, NOT POSITIONS. Computed positions come from
the depth chart's own vocabulary ("WR", rank 5); reported positions are
free text a human wrote ("WR5 / WR6 (back end of the receiver room)",
"Nickel / slot CB"). Those will never match. But if a reported battle
lists Tua Tagovailoa and Michael Penix Jr. as contenders, and a computed
slot flipped between those same two men, it is the same battle regardless
of what either side called the position.

    python crossref.py
    python crossref.py --fantasy
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
import warnings
from pathlib import Path

import pandas as pd

warnings.filterwarnings("ignore")
pd.set_option("display.width", 250)
pd.set_option("display.max_colwidth", 60)

HERE = Path(__file__).parent
COMPUTED = HERE / "true_battles.parquet"
REPORTED = HERE / "reported.json"

SUFFIX = re.compile(r"\b(jr|sr|ii|iii|iv|v)\b")


def norm(name: str) -> str:
    """Normalise a player name enough to survive two different typists.

    Nicknames in quotes, generational suffixes, punctuation and accents
    all differ between a depth chart and a beat writer's prose. What is
    left is first+last lowercased, which is what actually has to match.
    """
    if not isinstance(name, str):
        return ""
    n = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    n = re.sub(r'"[^"]*"', " ", n)          # Antwane "Juice" Wells
    n = re.sub(r"\([^)]*\)", " ", n)        # Ikem Ekwonu (injured)
    n = n.lower().replace(".", " ").replace("'", "").replace("-", " ")
    n = SUFFIX.sub(" ", n)
    return " ".join(n.split())


def load_reported() -> pd.DataFrame:
    if not REPORTED.exists():
        raise SystemExit("no reported.json -- run:  python harvest.py")
    raw = json.loads(REPORTED.read_text())
    rows = []
    for team, d in raw.items():
        for b in d.get("battles", []):
            names = [norm(c) for c in b.get("contenders", []) if norm(c)]
            rows.append({
                "team": team,
                "r_pos": b.get("position", ""),
                "names": frozenset(names),
                "n_contenders": len(names),
                "realness": b.get("realness", ""),
                "why": b.get("why", ""),
                "stakes": b.get("stakes", ""),
                "money": b.get("moneyNote", ""),
            })
    return pd.DataFrame(rows)


def load_computed() -> pd.DataFrame:
    c = pd.read_parquet(COMPUTED).reset_index(drop=True)
    from battles import as_list
    c["contenders"] = c.contenders.apply(as_list)
    c["names"] = c.contenders.apply(lambda h: frozenset(norm(x) for x in h))
    if not c.names.map(len).sum():
        raise SystemExit("contenders parsed to nothing -- check true_battles.parquet")
    return c


def match(comp: pd.DataFrame, rep: pd.DataFrame) -> pd.DataFrame:
    """Attach the best-overlapping reported battle to each computed slot.

    Best = most shared players. One shared name is enough to link when
    the reported battle names four contenders and the chart only ever
    flipped between two of them, which is the common case.
    """
    out = []
    by_team = {t: g for t, g in rep.groupby("team")}
    for row in comp.itertuples():
        best, best_n = None, 0
        for r in by_team.get(row.team, pd.DataFrame()).itertuples():
            n = len(row.names & r.names)
            if n > best_n:
                best, best_n = r, n
        out.append({
            "shared": best_n,
            "r_pos": best.r_pos if best is not None else None,
            "realness": best.realness if best is not None else None,
            "why": best.why if best is not None else None,
            "stakes": best.stakes if best is not None else None,
            "money": best.money if best is not None else None,
        })
    return pd.concat([comp.reset_index(drop=True), pd.DataFrame(out)], axis=1)


def media_only(rep: pd.DataFrame, comp: pd.DataFrame) -> pd.DataFrame:
    """Reported battles no computed slot ever touched."""
    seen = {}
    for row in comp.itertuples():
        seen.setdefault(row.team, set()).update(row.names)
    hit = [bool(r.names & seen.get(r.team, set())) for r in rep.itertuples()]
    return rep[~pd.Series(hit, index=rep.index)]


DEF = re.compile(r"\b(CB|DE|DT|LB|S|safety|corner|nickel|edge|linebacker|"
                 r"defensive|pass.rush)\b", re.I)
OL = re.compile(r"\b(LG|RG|LT|RT|C|guard|tackle|center|line)\b", re.I)
OFF = re.compile(r"\b(QB|RB|WR|TE|K|kicker|punt|return|running back|receiver|"
                 r"tight end|quarterback)\b", re.I)


def side_of_ball(pos: str) -> str:
    """Bucket a free-text position. Offense wins ties: "WR3 / slot CB" is
    a receiver question that mentions a corner."""
    p = str(pos)
    if OFF.search(p) and not DEF.search(p):
        return "offense-skill"
    if DEF.search(p):
        return "defense"
    if OL.search(p):
        return "o-line"
    return "other"


def resolution_check(rep: pd.DataFrame, mo: pd.DataFrame) -> pd.DataFrame:
    """How much of MEDIA ONLY is the chart simply not having the row.

    Run this before quoting any MEDIA ONLY number. If invisibility tracks
    side of the ball, the bucket is measuring chart resolution and not
    media behaviour.
    """
    r = rep.assign(side=rep.r_pos.map(side_of_ball))
    m = mo.assign(side=mo.r_pos.map(side_of_ball))
    t = pd.DataFrame({"reported": r.side.value_counts(),
                      "invisible": m.side.value_counts()}).fillna(0).astype(int)
    t["pct_invisible"] = (t.invisible / t.reported * 100).round(0)
    return t.sort_values("pct_invisible", ascending=False)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fantasy", action="store_true")
    a = ap.parse_args()

    rep, comp = load_reported(), load_computed()
    covered = sorted(rep.team.unique())
    comp = comp[comp.team.isin(covered)]          # only judge teams we researched
    print(f"{len(rep)} reported battles across {len(covered)} researched teams")
    print(f"{len(comp)} computed contested slots on those same teams\n")

    m = match(comp, rep)
    if a.fantasy:
        m, rep = m[m.fantasy], rep
        print("--- fantasy-relevant computed slots only ---\n")

    both = m[m.shared > 0]
    data_only = m[m.shared == 0]
    print(f"BOTH        {len(both):>4}   computed and covered")
    print(f"DATA ONLY   {len(data_only):>4}   chart moved, nobody wrote about it")

    mo = media_only(rep, comp)
    print(f"MEDIA ONLY  {len(mo):>4}   covered, chart never moved\n")

    print("=== VALIDATED: data and media agree ===")
    cols = ["team", "pos", "rank", "flips", "current", "fantasy", "realness", "r_pos"]
    print(both.sort_values(["fantasy", "flips"], ascending=False)[cols]
          .head(15).to_string(index=False))

    print("\n=== DATA ONLY: uncovered, and the chart keeps moving ===")
    d = data_only.sort_values(["fantasy", "flips"], ascending=False)
    print(d[["team", "pos", "rank", "flips", "contenders", "current", "fantasy"]]
          .head(15).to_string(index=False))

    print("\n=== MEDIA ONLY: covered, but the chart never moved ===")
    print(mo.sort_values("n_contenders", ascending=False)
          [["team", "r_pos", "n_contenders", "realness"]].head(15).to_string(index=False))

    print("\n=== is MEDIA ONLY real, or is the chart just blind here? ===")
    print(resolution_check(rep, mo).to_string())
    print("Read down pct_invisible. If defense is far higher than o-line, this\n"
          "bucket is chart resolution, not media invention. Quote DATA ONLY.")

    print("\n=== how the agents' own realness call lines up with the data ===")
    tab = pd.crosstab(m.realness.fillna("(uncovered)"), m.fantasy)
    print(tab.to_string())

    m.drop(columns=["names"]).to_parquet(HERE / "crossref.parquet")
    print(f"\nwrote crossref.parquet ({len(m)} rows)")
