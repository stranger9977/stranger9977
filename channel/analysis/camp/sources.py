"""Three independent reads on who is starting, in one schema.

The point of three sources is not redundancy, it is DISAGREEMENT. Where
ESPN, Ourlads and Rotowire agree, the job is settled. Where they diverge,
somebody is guessing -- and that is the camp battle.

    espn      via nflverse. Daily timestamped snapshots, free, already
              historical back to Mar 2026. Works today.
    ourlads   scraped. Hand-maintained, slow to move, strong on the
              offensive line where the other two are lazy.
    rotowire  scraped. Fantasy-facing, moves fastest on skill positions.

All three normalise to:
    source, team, pos, rank, player, scraped_at

NOTE ON EGRESS: ourlads.com and rotowire.com are blocked from the sandbox
this was written in (curl returns 000). The scrapers are therefore
UNTESTED against live HTML. Run them locally first and expect the
selectors to need one pass of fixing -- they are written from the
published page structure, not from a live response.
"""

from __future__ import annotations

import datetime as dt
import re
import time

import pandas as pd
import requests

UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"}

TEAMS = ["ARI","ATL","BAL","BUF","CAR","CHI","CIN","CLE","DAL","DEN","DET","GB",
         "HOU","IND","JAX","KC","LV","LAC","LA","MIA","MIN","NE","NO","NYG",
         "NYJ","PHI","PIT","SF","SEA","TB","TEN","WAS"]

# Ourlads uses a few different abbreviations than nflverse.
OURLADS_ABBR = {"LA": "LAR", "LV": "LVR", "WAS": "WAS", "JAX": "JAX"}

SCHEMA = ["source", "team", "pos", "rank", "player", "scraped_at"]


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


# ---------------------------------------------------------------- espn
def espn(season: int = 2026) -> pd.DataFrame:
    """Current ESPN depth chart via nflverse. This one is known-good."""
    import nfl_data_py as nfl

    d = nfl.import_depth_charts([season])
    d["dt"] = pd.to_datetime(d["dt"], utc=True).dt.tz_localize(None)
    d = d[d.dt == d.dt.max()]
    out = pd.DataFrame({
        "source": "espn",
        "team": d.team,
        "pos": d.pos_abb,
        "rank": d.pos_rank.astype(int),
        "player": d.player_name,
        "scraped_at": _now(),
    })
    return out.dropna(subset=["player"]).reset_index(drop=True)[SCHEMA]


# ------------------------------------------------------------- ourlads
def ourlads(teams=None, pause: float = 1.5) -> pd.DataFrame:
    """Scrape Ourlads depth charts.

    Page layout: one <table> of rows, each row = a position, with the
    starter and backups in successive cells as "LASTNAME, FIRSTNAME 00".
    """
    from bs4 import BeautifulSoup

    rows = []
    for t in (teams or TEAMS):
        slug = OURLADS_ABBR.get(t, t)
        url = f"https://www.ourlads.com/nfldepthcharts/depthchart/{slug}"
        try:
            html = requests.get(url, headers=UA, timeout=25).text
        except Exception as e:  # noqa: BLE001
            print(f"  ourlads {t}: {type(e).__name__}")
            continue

        soup = BeautifulSoup(html, "html.parser")
        for tr in soup.select("tr"):
            cells = [c.get_text(" ", strip=True) for c in tr.select("td")]
            if len(cells) < 3 or not cells[0]:
                continue
            pos = cells[0].upper()
            if not re.fullmatch(r"[A-Z0-9/]{1,6}", pos):
                continue
            for i, raw in enumerate(cells[1:], start=1):
                name = _clean_ourlads(raw)
                if name:
                    rows.append(("ourlads", t, pos, i, name, _now()))
        time.sleep(pause)
    return pd.DataFrame(rows, columns=SCHEMA)


def _clean_ourlads(cell: str) -> str | None:
    """'JOHNSON, LANE 65' -> 'Lane Johnson'."""
    cell = re.sub(r"\s*\d+\s*$", "", cell).strip()
    cell = re.sub(r"\s*\((?:R|IR|PUP|NFI|SUS)\)\s*", "", cell, flags=re.I).strip()
    if not cell or "," not in cell:
        return None
    last, first = (p.strip() for p in cell.split(",", 1))
    if not last or not first:
        return None
    return f"{first.title()} {last.title()}"


# ------------------------------------------------------------ rotowire
def rotowire(pause: float = 1.5) -> pd.DataFrame:
    """Scrape Rotowire's league-wide depth chart page.

    Rotowire renders one block per team; within a block, each position row
    lists players in order. Selectors are the fragile part -- verify.
    """
    from bs4 import BeautifulSoup

    url = "https://www.rotowire.com/football/depth-charts.php"
    try:
        html = requests.get(url, headers=UA, timeout=30).text
    except Exception as e:  # noqa: BLE001
        print(f"  rotowire: {type(e).__name__}")
        return pd.DataFrame(columns=SCHEMA)

    soup = BeautifulSoup(html, "html.parser")
    rows = []
    for block in soup.select("[class*=depth-chart], [class*=dc-team]"):
        head = block.select_one("[class*=team], h2, h3")
        team = _team_from_text(head.get_text(strip=True) if head else "")
        if not team:
            continue
        for tr in block.select("tr"):
            cells = [c.get_text(" ", strip=True) for c in tr.select("td")]
            if len(cells) < 2 or not cells[0]:
                continue
            pos = cells[0].upper()
            if not re.fullmatch(r"[A-Z0-9/]{1,6}", pos):
                continue
            for i, name in enumerate(cells[1:], start=1):
                name = re.sub(r"\s*\((?:Q|D|O|IR|PUP)\)\s*", "", name).strip()
                if name and not name.isdigit():
                    rows.append(("rotowire", team, pos, i, name, _now()))
    return pd.DataFrame(rows, columns=SCHEMA)


_NAME_TO_ABBR = {
    "cardinals":"ARI","falcons":"ATL","ravens":"BAL","bills":"BUF","panthers":"CAR",
    "bears":"CHI","bengals":"CIN","browns":"CLE","cowboys":"DAL","broncos":"DEN",
    "lions":"DET","packers":"GB","texans":"HOU","colts":"IND","jaguars":"JAX",
    "chiefs":"KC","raiders":"LV","chargers":"LAC","rams":"LA","dolphins":"MIA",
    "vikings":"MIN","patriots":"NE","saints":"NO","giants":"NYG","jets":"NYJ",
    "eagles":"PHI","steelers":"PIT","49ers":"SF","seahawks":"SEA","buccaneers":"TB",
    "titans":"TEN","commanders":"WAS",
}


def _team_from_text(s: str) -> str | None:
    s = s.lower()
    for key, abbr in _NAME_TO_ABBR.items():
        if key in s:
            return abbr
    return None


# ------------------------------------------------------------ combine
def snapshot(use_scrapers: bool = True) -> pd.DataFrame:
    """All available sources, one frame."""
    frames = [espn()]
    if use_scrapers:
        for fn in (ourlads, rotowire):
            try:
                df = fn()
                if len(df):
                    frames.append(df)
                else:
                    print(f"  {fn.__name__}: returned nothing")
            except Exception as e:  # noqa: BLE001
                print(f"  {fn.__name__} failed: {type(e).__name__}: {e}")
    out = pd.concat(frames, ignore_index=True)
    print(f"snapshot: {len(out)} rows from {out.source.nunique()} source(s) "
          f"-> {sorted(out.source.unique())}")
    return out
