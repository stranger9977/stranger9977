"""Inline camp.json into the Undercard template.

    python payload.py && python build_undercard.py    ->  undercard2.html

The data is injected rather than fetched because a published artifact runs
under a Content Security Policy that blocks every external host -- there is
no origin to fetch from, so the payload has to be part of the document.
"""

from pathlib import Path

HERE = Path(__file__).parent
TPL = HERE / "undercard2.tpl.html"
DATA = HERE / "camp.json"
OUT = HERE / "undercard2.html"

if __name__ == "__main__":
    for p in (TPL, DATA):
        if not p.exists():
            raise SystemExit(f"missing {p.name}")
    html = TPL.read_text().replace("/*DATA*/", DATA.read_text())
    OUT.write_text(html)
    print(f"wrote {OUT.name} ({OUT.stat().st_size // 1024} KB)")
