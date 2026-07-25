#!/usr/bin/env python3
"""Build the four themed artifacts: inline chart PNGs as data URIs and
substitute cross-links. Run from nfl-analysis/.

    python3 report/build.py            # build with placeholder cross-links
    python3 report/build.py links.json # build with real artifact URLs
"""
import base64, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORT = os.path.join(ROOT, "report")
CHARTS = os.path.join(ROOT, "charts")
PARTS = ["grind", "tell", "ice", "clock"]

links = {}
if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
    links = json.load(open(sys.argv[1]))

for part in PARTS:
    src = os.path.join(REPORT, f"_src_{part}.html")
    html = open(src).read()

    slugs = []
    for s in re.findall(r"CHART:([A-Za-z0-9_\-]+)", html):
        if s not in slugs:
            slugs.append(s)
    for slug in slugs:
        png = os.path.join(CHARTS, f"{slug}.png")
        if not os.path.exists(png):
            raise SystemExit(f"{part}: missing chart {png}")
        uri = "data:image/png;base64," + base64.b64encode(open(png, "rb").read()).decode()
        html = html.replace(f"CHART:{slug}", uri)

    for other in PARTS:
        html = html.replace(f"LINK:{other}", links.get(other, "#"))

    assert "CHART:" not in html and "LINK:" not in html, part
    out = os.path.join(REPORT, f"{part}.html")
    open(out, "w").write(html)
    print(f"{part:7s} {len(slugs)} charts  {len(html)//1024:5d} KB  -> report/{part}.html")
