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
  MEDIA ONLY  heavily covered, chart never moved. Either the competition
              is rhetorical, or the team has already decided and is
              saying otherwise.

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
    c["names"] = c.contenders.apply(lambda h: frozenset(norm(x) for x in h))
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

    print("\n=== how the agents' own realness call lines up with the data ===")
    tab = pd.crosstab(m.realness.fillna("(uncovered)"), m.fantasy)
    print(tab.to_string())

    m.drop(columns=["names"]).to_parquet(HERE / "crossref.parquet")
    print(f"\nwrote crossref.parquet ({len(m)} rows)")
