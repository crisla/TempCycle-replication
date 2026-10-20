#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Expected-remaining-duration figures (Weibull-mixture calibration).

Exports the figure-producing cells of
`notebooks/Results Interpretation Figures.ipynb` for headless running.
For each country the two-type Weibull mixture with a common shape k is
calibrated to the 2011-window variance-decomposition moments, and the
analytic inverse hazard 1/h(t) (expected remaining duration) is plotted.

Writes
    output/figures/exp_dur_base_a.png    all unstable spells
    output/figures/exp_dur_T_a.png       temporary-contract spells only
    output/figures/het_DD_base_a.png     change in expected remaining duration

Inputs: Stata logs in data/intermediate/{spain/results,germany}/. No
microdata and no random draws (the figures are analytic), so no seed.

The notebook's simulation cells (calibration check, 101M-draw hazard
simulation, data-vs-model survival plot) need the individual-level
Spanish duration extract and do not feed any saved figure; they stay in
the notebook only.

Run from the repository root (run_all.py does this).
"""

import csv

import matplotlib
matplotlib.use("Agg")  # headless backend
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sn
from matplotlib.lines import Line2D
from scipy.special import gamma

sn.set_style("whitegrid")

SPA_RES = "./data/intermediate/spain/results/"
GER_RES = "./data/intermediate/germany/"
FIG_DIR = "./output/figures/"

MONTHS_GRID = 72       # x-axis range, months
DAYS_PER_MONTH = 30    # the duration data are measured in days


# ── Decomposition log parser ───────────────────────────────────────────────
def pass_to_csv(file_name, path_res, keyword="Variable"):
    """Parse the Stata decomposition .log into .csv tables next to it."""
    results_now = 0
    table_num = 0
    with open(path_res + file_name + ".log") as file:
        lines = file.read().splitlines()
    output = []
    for line in lines:
        words = line.replace("|", "").split()
        if len(words) > 1 and words[0] == keyword:
            results_now = 1
        if len(words) > 5 and results_now:
            output.append(line.replace("|", "").split())
        if len(words) > 5 and words[0] == "mu_y":
            results_now = 0
            fname = (path_res + file_name + ".csv" if table_num == 0
                     else path_res + file_name + "_{}.csv".format(table_num + 1))
            with open(fname, "w+") as csvfile:
                csv.writer(csvfile).writerows(output)
            table_num += 1
            output = []


def load_moments(file_name, path_res, label):
    """Return [mu_y, lsig_y2, lsig_b2, lsig_e2] for the first table in a log."""
    pass_to_csv(file_name, path_res)
    res = pd.read_csv(path_res + file_name + ".csv", index_col=0).T
    res = res.rename(index={"Mean": label}).loc[label]
    return np.array([res.mu_y, res.lsig_y2, res.lsig_b2, res.lsig_e2])


# ── Weibull-mixture calibration and analytic inverse hazard ───────────────
def get_params_2l1k(moms):
    """Two-type Weibull mixture with common shape k and equal weights.

    moms = [mu_y, lsig_b, lsig_w]; returns (lambda, alpha, k) such that the
    spell-duration distribution is Mix(Weibull(lambda,k), Weibull(alpha*lambda,k)).
    """
    mu_y, lsig_b, lsig_w = moms
    k = np.pi / np.sqrt(6 * lsig_w)
    alpha = np.exp(2 * np.sqrt(lsig_b))
    lbda = 2 * mu_y / (gamma(1 + 1 / k) * (1 + alpha))
    return lbda, alpha, k


def calibrate(moms):
    """Calibrate from [mu_y, lsig_y2, lsig_b2, lsig_e2]; lsig_w = lsig_e2 + pi^2/6."""
    return get_params_2l1k([moms[0], moms[2], moms[3] + np.pi**2 / 6])


def inv_hazard_weibull_mix(t_days, lbda, alpha, k):
    """Analytic 1/h(t) in days for a 50/50 Weibull mixture (scales lbda, alpha*lbda)."""
    s_a = np.exp(-(t_days / lbda) ** k)
    s_b = np.exp(-(t_days / (alpha * lbda)) ** k)
    f_a = (k / lbda) * (t_days / lbda) ** (k - 1) * s_a
    f_b = (k / (alpha * lbda)) * (t_days / (alpha * lbda)) ** (k - 1) * s_b
    return 0.5 * (s_a + s_b) / (0.5 * (f_a + f_b))


# ── Figures ────────────────────────────────────────────────────────────────
def plot_inverse_hazards(spa_moms, ger_moms, ylim_top, out_name):
    """Line plot: Het+DD (common k), Het only (k=1) and exponential fit, by country."""
    t_days = np.linspace(1, MONTHS_GRID * DAYS_PER_MONTH, 5_000)
    t_months = t_days / DAYS_PER_MONTH
    colors = sn.color_palette()

    fig = plt.figure()
    for moms, c_dd, c_het, c_expo in (
        (ger_moms, "navy", "tab:blue", "black"),
        (spa_moms, "darkred", colors[1], "purple"),
    ):
        lbda, alpha, k = calibrate(moms)
        plt.plot(t_months, inv_hazard_weibull_mix(t_days, lbda, alpha, k) / DAYS_PER_MONTH, c=c_dd)
        plt.plot(t_months, inv_hazard_weibull_mix(t_days, lbda, alpha, 1.0) / DAYS_PER_MONTH, c=c_het)
        plt.plot(t_months, np.full_like(t_days, moms[0] / DAYS_PER_MONTH), c=c_expo, ls="--")

    plt.xlim(0, MONTHS_GRID)
    plt.ylim(0, ylim_top)
    plt.xticks(range(12, MONTHS_GRID + 1, 12))
    plt.xlabel("Months elapsed in spell")
    plt.ylabel("Expected remaining duration (months)")

    legend_elements = [
        Line2D([0], [0], color="none", label="Germany"),
        Line2D([0], [0], color="navy", label="Heterogeneity + DD"),
        Line2D([0], [0], color="tab:blue", label="Heterogeneity Only"),
        Line2D([0], [0], color="black", linestyle="--", label="Exponential fit"),
        Line2D([0], [0], color="none", label="Spain"),
        Line2D([0], [0], color="darkred", label="Heterogeneity + DD"),
        Line2D([0], [0], color=colors[1], label="Heterogeneity Only"),
        Line2D([0], [0], color="purple", linestyle="--", label="Exponential fit"),
    ]
    plt.legend(handles=legend_elements, loc="upper center",
               bbox_to_anchor=(0.71, 1.015), ncol=2, fontsize=9)
    plt.tight_layout()
    plt.savefig(FIG_DIR + out_name, bbox_inches="tight", dpi=300)
    plt.close(fig)
    print("Saved", FIG_DIR + out_name)


def plot_het_dd_bars(spa_moms, ger_moms, out_name):
    """Bars: gain in expected remaining duration after 12..72 months vs a new entrant."""
    months_bar = np.array([12, 24, 36, 48, 60, 72])
    t_bar_days = months_bar * DAYS_PER_MONTH
    t0_days = np.array([0.5 * DAYS_PER_MONTH])  # new entrant: midpoint of first month
    x = np.arange(len(months_bar))

    fig, (ax_spa, ax_ger) = plt.subplots(1, 2, figsize=(12, 4))
    for ax, moms, name, c_dd, c_het in (
        (ax_spa, spa_moms, "Spain", "darkred", "tab:orange"),
        (ax_ger, ger_moms, "Germany", "navy", "tab:blue"),
    ):
        lbda, alpha, k = calibrate(moms)
        gain_dd = (inv_hazard_weibull_mix(t_bar_days, lbda, alpha, k)
                   - inv_hazard_weibull_mix(t0_days, lbda, alpha, k)[0]) / DAYS_PER_MONTH
        gain_het = (inv_hazard_weibull_mix(t_bar_days, lbda, alpha, 1.0)
                    - inv_hazard_weibull_mix(t0_days, lbda, alpha, 1.0)[0]) / DAYS_PER_MONTH
        ax.bar(x, gain_dd, width=0.3, label="Heterogeneity + DD", color=c_dd)
        ax.bar(x + 0.3, gain_het, width=0.3, label="Heterogeneity only", color=c_het)
        ax.set_ylim(0, 20)
        ax.set_yticks(np.arange(0, 21, 2))
        ax.set_xticks(x + 0.15)
        ax.set_xticklabels([str(m) for m in months_bar])
        ax.set_xlabel("Months elapsed in spell")
        ax.set_ylabel("Gain in expected remaining duration (months)")
        ax.set_title(name)
        ax.legend(loc="upper left")

    plt.tight_layout()
    plt.savefig(FIG_DIR + out_name, dpi=300)
    plt.close(fig)
    print("Saved", FIG_DIR + out_name)


def main():
    # 2011-window moments: all unstable spells (base) and temporary-only spells.
    spa_moms = load_moments("results2011_T_harm", SPA_RES, "Spain")
    ger_moms = load_moments("031_decomp_2011", GER_RES, "Germany")
    spa_moms_t = load_moments("results2011_onlyT_harm", SPA_RES, "Spain")
    ger_moms_t = load_moments("041_decomp", GER_RES, "Germany")

    print("Spain moments  (mu_y, lsig_y2, lsig_b2, lsig_e2):", np.round(spa_moms, 4))
    print("Germany moments:", np.round(ger_moms, 4))

    plot_inverse_hazards(spa_moms, ger_moms, ylim_top=50, out_name="exp_dur_base_a.png")
    plot_inverse_hazards(spa_moms_t, ger_moms_t, ylim_top=30, out_name="exp_dur_T_a.png")
    plot_het_dd_bars(spa_moms, ger_moms, out_name="het_DD_base_a.png")


if __name__ == "__main__":
    main()
