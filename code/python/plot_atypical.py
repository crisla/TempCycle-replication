import os
import re
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# Resolve paths relative to this script so it runs from any working directory.
ROOT = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(ROOT, "agg_data")

# Stata `list year atypical N` log files, one per country.
SOURCES = {
    "Spain": os.path.join(ROOT, "spain", "descriptive_stats", "incidence_atypical_by_year.log"),
    "Germany": os.path.join(ROOT, "germany", "results", "05_descriptives.log"),
}

CSV_PATH = os.path.join(BASE, "atypical_incidence.csv")
PNG_PATH = os.path.join(BASE, "atypical_incidence_by_year.png")

# Matches table rows like:  1. | 2011   .3257515   5513430 |
ROW_RE = re.compile(r"\|\s*(\d{4})\s+([\d.]+)\s+(\d+)\s*\|")


def parse_log(path, country):
    """Extract (year, atypical, N) rows from the `list year atypical N` block."""
    with open(path) as f:
        lines = f.readlines()

    # Find the listing command, then read the box that follows.
    start = next(i for i, ln in enumerate(lines) if "list year atypical N" in ln)

    rows = []
    for ln in lines[start:]:
        m = ROW_RE.search(ln)
        if m:
            year, atypical, n = m.groups()
            rows.append({
                "year": int(year),
                "country": country,
                "atypical": float(atypical),
                "N": int(n),
            })
        elif rows and "+----" in ln:
            # Reached the closing border after collecting rows.
            break

    if not rows:
        raise ValueError(f"No data rows found in {path}")
    return rows


def build_csv():
    records = []
    for country, path in SOURCES.items():
        records.extend(parse_log(path, country))
    df = pd.DataFrame(records, columns=["year", "country", "atypical", "N"])
    df.to_csv(CSV_PATH, index=False)
    print(f"Saved: {CSV_PATH}")
    return df


def make_plot(df):
    spain = df[df["country"] == "Spain"]
    germany = df[df["country"] == "Germany"]

    fig, ax = plt.subplots(figsize=(9, 5))

    ax.plot(spain["year"], spain["atypical"], marker="o", label="Spain (Temporary Contracts)", color="darkred")
    ax.plot(germany["year"], germany["atypical"], marker="s", label="Germany (Mini Jobs and Temporary Contracts)", color="navy")

    ax.set_xlabel("Year", fontsize=12)
    ax.set_ylabel("Incidence of Atypical Employment", fontsize=12)
    ax.set_xticks(range(2011, 2022))
    ax.set_ylim(0, 1)
    ax.yaxis.set_major_formatter(mticker.FormatStrFormatter("%.1f"))
    ax.legend(fontsize=11)
    ax.grid(axis="y", linestyle="--", alpha=0.5)

    plt.tight_layout()
    plt.savefig(PNG_PATH, dpi=150)
    print(f"Saved: {PNG_PATH}")


if __name__ == "__main__":
    df = build_csv()
    make_plot(df)
