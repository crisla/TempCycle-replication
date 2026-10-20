#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Spain sample-selection figures, rebuilt from the shipped GMM estimates.

`sample_selection_spain.py` needs the individual-level MCVL duration
extracts, so under `run_all.py` without microdata it is skipped. Everything
these figures plot is, however, already stored in
`output/sample_selection/selection_spain.json` (fitted type shares and the
implied population / one-spell / two-spell type compositions by window), so
the figures are redrawn from that file with no data access.

Writes (output/sample_selection/)
    type_composition_paper_discrete.png   population vs 1 spell vs 2+ spells, 4 windows
    type_composition_paper_simple.png     population vs estimation sample, 4 windows
    type_grid_2x2.png                     the 2x2 type diagram (lambda x delta)

Mirrors the figure cells of `notebooks/Sample Selection Discrete.ipynb`.
No random draws, so no seed. Run from the repository root.
"""

import json

import matplotlib
matplotlib.use("Agg")  # headless backend
import matplotlib.pyplot as plt
import numpy as np

JSON_PATH = "./output/sample_selection/selection_spain.json"
OUT_DIR = "./output/sample_selection/"

TYPE_LABELS = ["HH", "HL", "LH", "LL"]
TYPE_NAMES = ["Fast cycler", "Stable worker", "Unstable worker", "Slow cycler"]
TYPE_COLORS = ["#e74c3c", "#3498db", "#f39c12", "#2ecc71"]


def composition(window, group):
    """Type shares (HH, HL, LH, LL) of one group in one estimation window."""
    return np.array([window[group][t] for t in TYPE_LABELS])


def stacked_bars(ax, labels, columns, fontsize):
    """Stack the four types in each column; columns is a list of (4,) arrays."""
    bottom = np.zeros(len(columns))
    for t in range(4):
        heights = np.array([col[t] for col in columns])
        ax.bar(labels, heights, bottom=bottom,
               label=f"{TYPE_LABELS[t]}: {TYPE_NAMES[t]}",
               color=TYPE_COLORS[t], alpha=0.85, edgecolor="white", linewidth=0.5)
        for xi, (h, b) in enumerate(zip(heights, bottom)):
            if h > 0.04:  # label inside the bar only if it fits
                ax.text(xi, b + h / 2, f"{h:.2f}", ha="center", va="center",
                        fontsize=fontsize, color="white", fontweight="bold")
        bottom += heights


def figure_discrete(windows, end_year):
    fig, axes = plt.subplots(2, 2, figsize=(11, 8), sharey=True)
    for ax, win in zip(axes.flat, windows):
        stacked_bars(ax, ["Population", "1 Spell", "2+ Spells"],
                     [composition(win, "population"),
                      composition(win, "one_spell"),
                      composition(win, "two_spell")], fontsize=7)
        ax.set_ylim(0, 1.05)
        ax.set_xlabel("Sample")
        ax.set_ylabel("Type share")
        ax.set_title(f"{win['horizon']}-year horizon ({win['year']}–{end_year})", fontsize=10)
        ax.legend(fontsize=7, loc="upper right", bbox_to_anchor=(1.35, 1.0))
    fig.suptitle("Type composition: population vs one-cycle sample vs "
                 "two-cycle (estimation) sample", fontsize=11)
    fig.tight_layout()
    fig.savefig(OUT_DIR + "type_composition_paper_discrete.png", bbox_inches="tight", dpi=300)
    plt.close(fig)


def figure_simple(windows, end_year):
    fig, axes = plt.subplots(1, 4, figsize=(13, 4), sharey=True)
    for ax, win in zip(axes.flat, windows):
        stacked_bars(ax, ["Population", "Sample"],
                     [composition(win, "population"),
                      composition(win, "two_spell")], fontsize=9)
        ax.set_ylim(0, 1.02)
        ax.set_xlabel("Sample")
        ax.set_title(f"{win['horizon']}-year horizon ({win['year']}–{end_year})", fontsize=11)
    axes[0].set_ylabel("Type share", fontsize=11)
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="lower center", ncol=4, fontsize=10,
               frameon=False, bbox_to_anchor=(0.5, -0.06))
    fig.tight_layout()
    fig.savefig(OUT_DIR + "type_composition_paper_simple.png", bbox_inches="tight", dpi=300)
    plt.close(fig)


def figure_grid():
    """2x2 type diagram: columns lambda_L / lambda_H, rows delta_H (bottom) / delta_L (top)."""
    cell_map = {(0, 1): 3,   # top-left:     LL slow cycler
                (1, 1): 1,   # top-right:    HL stable worker
                (0, 0): 2,   # bottom-left:  LH unstable worker
                (1, 0): 0}   # bottom-right: HH fast cycler
    fig, ax = plt.subplots(figsize=(7, 5.5))
    for (cx, cy), t in cell_map.items():
        ax.add_patch(plt.Rectangle((cx, cy), 1, 1, facecolor=TYPE_COLORS[t],
                                   alpha=0.85, edgecolor="white", linewidth=2))
        ax.text(cx + 0.5, cy + 0.5, f"{TYPE_LABELS[t]}\n{TYPE_NAMES[t]}",
                ha="center", va="center", fontsize=14, color="white", fontweight="bold")
    ax.text(0.5, 2.08, r"$\lambda_L$", ha="center", fontsize=18)
    ax.text(1.5, 2.08, r"$\lambda_H$", ha="center", fontsize=18)
    ax.text(-0.12, 1.5, r"$\delta_L$", va="center", ha="right", fontsize=18)
    ax.text(-0.12, 0.5, r"$\delta_H$", va="center", ha="right", fontsize=18)
    ax.set_xlim(-0.4, 2.05)
    ax.set_ylim(-0.05, 2.3)
    ax.set_aspect("equal")
    ax.axis("off")
    fig.tight_layout()
    fig.savefig(OUT_DIR + "type_grid_2x2.png", bbox_inches="tight", dpi=300, transparent=True)
    plt.close(fig)


def main():
    with open(JSON_PATH) as handle:
        est = json.load(handle)
    # Windows are stored shortest-horizon-first matching the YEARS order in the script.
    figure_discrete(est["windows"], est["end_year"])
    figure_simple(est["windows"], est["end_year"])
    figure_grid()
    print("Saved Spain sample-selection figures to", OUT_DIR)


if __name__ == "__main__":
    main()
