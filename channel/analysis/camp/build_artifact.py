"""Inject the churn data into the Undercard artifact template.

    python build_artifact.py    ->  undercard.html

Team metadata (camp site, coordinates, colour) is hardcoded because
nfl_data_py.import_team_desc is blocked by the egress proxy here.
Coordinates are the actual training camp site, not the stadium --
Dallas camps in Oxnard, KC in St. Joseph, Pittsburgh in Latrobe.
"""
import json
import warnings

import pandas as pd

warnings.filterwarnings("ignore")

# abbr: (name, camp site, lat, lon, primary colour)
META = {
    "ARI": ("Cardinals", "Tempe, AZ", 33.43, -111.94, "#97233F"),
    "ATL": ("Falcons", "Flowery Branch, GA", 34.18, -83.92, "#A71930"),
    "BAL": ("Ravens", "Owings Mills, MD", 39.42, -76.78, "#241773"),
    "BUF": ("Bills", "Orchard Park, NY", 42.77, -78.79, "#00338D"),
    "CAR": ("Panthers", "Charlotte, NC", 35.23, -80.85, "#0085CA"),
    "CHI": ("Bears", "Lake Forest, IL", 42.24, -87.84, "#0B162A"),
    "CIN": ("Bengals", "Cincinnati, OH", 39.10, -84.52, "#FB4F14"),
    "CLE": ("Browns", "Berea, OH", 41.37, -81.85, "#FF3C00"),
    "DAL": ("Cowboys", "Oxnard, CA", 34.20, -119.18, "#003594"),
    "DEN": ("Broncos", "Englewood, CO", 39.65, -104.99, "#FB4F14"),
    "DET": ("Lions", "Allen Park, MI", 42.26, -83.21, "#0076B6"),
    "GB": ("Packers", "Green Bay, WI", 44.50, -88.06, "#FFB612"),
    "HOU": ("Texans", "Houston, TX", 29.68, -95.41, "#03A0F0"),
    "IND": ("Colts", "Westfield, IN", 40.04, -86.13, "#002C5F"),
    "JAX": ("Jaguars", "Jacksonville, FL", 30.32, -81.64, "#9F792C"),
    "KC": ("Chiefs", "St. Joseph, MO", 39.77, -94.85, "#E31837"),
    "LV": ("Raiders", "Henderson, NV", 36.03, -115.04, "#A5ACAF"),
    "LAC": ("Chargers", "El Segundo, CA", 33.92, -118.41, "#0080C6"),
    "LA": ("Rams", "Thousand Oaks, CA", 34.19, -118.87, "#FFD100"),
    "MIA": ("Dolphins", "Miami Gardens, FL", 25.96, -80.24, "#008E97"),
    "MIN": ("Vikings", "Eagan, MN", 44.81, -93.17, "#4F2683"),
    "NE": ("Patriots", "Foxborough, MA", 42.09, -71.26, "#C60C30"),
    "NO": ("Saints", "Metairie, LA", 30.00, -90.18, "#D3BC8D"),
    "NYG": ("Giants", "East Rutherford, NJ", 40.81, -74.07, "#0B2265"),
    "NYJ": ("Jets", "Florham Park, NJ", 40.78, -74.39, "#125740"),
    "PHI": ("Eagles", "Philadelphia, PA", 39.90, -75.18, "#004C54"),
    "PIT": ("Steelers", "Latrobe, PA", 40.32, -79.38, "#FFB612"),
    "SF": ("49ers", "Santa Clara, CA", 37.40, -121.97, "#AA0000"),
    "SEA": ("Seahawks", "Renton, WA", 47.49, -122.19, "#69BE28"),
    "TB": ("Buccaneers", "Tampa, FL", 27.98, -82.51, "#D50A0A"),
    "TEN": ("Titans", "Nashville, TN", 36.16, -86.77, "#4B92DB"),
    "WAS": ("Commanders", "Ashburn, VA", 39.03, -77.49, "#5A1414"),
}


def main():
    battles = json.load(open("battles.json"))
    teams = {}
    for a, (name, camp, lat, lon, col) in META.items():
        b = battles.get(a, {"total": 0, "starter": 0, "depth": 0, "battles": []})
        teams[a] = dict(name=name, camp=camp, lat=lat, lon=lon, color=col, **b)

    d = pd.read_parquet("rank123_daily.parquet")
    post = d[d.d >= pd.Timestamp("2026-05-01")]
    rank = {str(int(k)): int(v) for k, v in post.groupby("pos_rank")["changed"].sum().items()}

    ann = pd.read_parquet("annual_starters.parquet")
    m = ann.groupby(pd.Grouper(key="d", freq="M"))["changed"].sum()
    months = [[dt.strftime("%b %y"), int(v)] for dt, v in m.items()
              if dt >= pd.Timestamp("2025-09-01")]

    payload = dict(teams=teams, rank=rank, months=months)
    tpl = open("undercard.tpl.html").read()
    open("undercard.html", "w").write(tpl.replace("/*DATA*/", json.dumps(payload, separators=(",", ":"))))
    print(f"32 teams, rank churn {rank}")


if __name__ == "__main__":
    main()
