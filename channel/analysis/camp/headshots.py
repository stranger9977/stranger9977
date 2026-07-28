"""Fetch player headshots and inline them as data URIs.

Headshot URLs live in nflverse: `import_seasonal_rosters()` has
`headshot_url`, `import_players()` has `headshot`. They point at
static.www.nfl.com.

WHY INLINE: published artifacts run under a Content Security Policy that
blocks every external host. A remote <img src> silently fails. So each
image has to be fetched, downscaled, and embedded as a base64 data URI.

WHY SMALL: a fight card only needs a ~96px circle. At that size a WebP is
roughly 3-5 KB, so ~200 players costs under a megabyte of HTML. Do NOT
inline full-size images -- a 32-team payload will run to tens of megabytes
and the artifact will not load.

    python headshots.py --players "Jalen Carter" "Lane Johnson"
    python headshots.py --from-battles battles.json --limit 200

NOTE: static.www.nfl.com is blocked from the sandbox this was written in
(curl returns 000), so the fetch path is UNTESTED here. It should work on
any unrestricted machine.

RIGHTS: these are NFL/team images. Fine for personal analysis and almost
certainly fine for editorial commentary use, but they are not yours. If the
artifact goes public and gets traffic, that is worth a real look rather
than an assumption.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
from pathlib import Path

import pandas as pd
import requests

HERE = Path(__file__).parent
CACHE = HERE / "headshots.json"
SIZE = 96
UA = {"User-Agent": "Mozilla/5.0"}


def url_map() -> dict[str, str]:
    """player_name -> headshot url, current season first."""
    import nfl_data_py as nfl

    m: dict[str, str] = {}
    for season in (2025, 2026):          # 2026 wins on collision
        try:
            r = nfl.import_seasonal_rosters([season])
        except Exception as e:  # noqa: BLE001
            print(f"  rosters {season}: {type(e).__name__}")
            continue
        col = "headshot_url" if "headshot_url" in r.columns else None
        if not col:
            continue
        for name, u in zip(r.player_name, r[col]):
            if isinstance(u, str) and u.startswith("http"):
                m[name] = u
    print(f"headshot urls available for {len(m)} players")
    return m


def fetch(url: str, size: int = SIZE) -> str | None:
    """Download, square-crop, downscale, return a data URI."""
    try:
        from PIL import Image
    except ImportError:
        raise SystemExit("needs Pillow:  pip install pillow")

    try:
        raw = requests.get(url, headers=UA, timeout=20).content
        im = Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception as e:  # noqa: BLE001
        print(f"  fetch failed: {type(e).__name__}")
        return None

    w, h = im.size
    side = min(w, h)
    im = im.crop(((w - side) // 2, 0, (w + side) // 2, side))
    im = im.resize((size, size), Image.LANCZOS)

    buf = io.BytesIO()
    try:
        im.save(buf, "WEBP", quality=78, method=6)
        mime = "image/webp"
    except Exception:  # noqa: BLE001
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=76, optimize=True)
        mime = "image/jpeg"
    return f"data:{mime};base64,{base64.b64encode(buf.getvalue()).decode()}"


def build(names: list[str], limit: int | None = None) -> dict[str, str]:
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    urls = url_map()

    todo = [n for n in dict.fromkeys(names) if n not in cache and n in urls]
    if limit:
        todo = todo[:limit]
    print(f"{len(cache)} cached, fetching {len(todo)}")

    for i, n in enumerate(todo, 1):
        uri = fetch(urls[n])
        if uri:
            cache[n] = uri
        if i % 25 == 0:
            print(f"  {i}/{len(todo)}")
            CACHE.write_text(json.dumps(cache))

    CACHE.write_text(json.dumps(cache))
    kb = len(json.dumps(cache)) // 1024
    print(f"cache: {len(cache)} headshots, {kb} KB")
    if kb > 3000:
        print("  WARNING: over 3 MB. Trim the roster or drop SIZE before inlining.")
    return cache


def names_from_battles(path: Path) -> list[str]:
    data = json.loads(Path(path).read_text())
    out = []
    for team in data.values():
        for b in team.get("battles", []):
            out.extend(b.get("contenders", []))
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--players", nargs="*", default=[])
    ap.add_argument("--from-battles", type=Path)
    ap.add_argument("--limit", type=int)
    a = ap.parse_args()

    names = list(a.players)
    if a.from_battles:
        names += names_from_battles(a.from_battles)
    if not names:
        raise SystemExit("give --players or --from-battles")
    build(names, a.limit)
