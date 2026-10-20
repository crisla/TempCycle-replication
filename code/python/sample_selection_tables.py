#!/usr/bin/env python3
"""Build the sample-selection LaTeX tables from the JSON emitted by the two
sample-selection scripts, into output/tables/sample_selection_tables.tex.

Inputs (written by sample_selection_discrete.py / sample_selection_germany.py):
    output/sample_selection/selection_spain.json
    output/sample_selection/selection_germany.json

Tables produced:
    tab:composition_spain    -- type composition by group & window (Spain)
    tab:composition_germany  -- type composition by group & window (Germany)
    tab:selection_dd         -- selection does not generate duration dependence

Run from the repo root (after the two sample-selection scripts):
    python sample_selection_tables.py
"""

import json
import os

OUT = "./output/tables/sample_selection_tables.tex"
TYPES = ["HH", "HL", "LH", "LL"]


def _load(country):
    with open(f"output/sample_selection/selection_{country}.json") as f:
        return json.load(f)


def _s(x):   # type shares / "Share" column
    return f"{x:.3f}"


def _h(x):   # hazard rates
    return f"{x:.4f}"


def _grp_row(label, g):
    """One data row: label & HH & HL & LH & LL & E[lam] & E[del] & Share."""
    cells = " & ".join(_s(g[t]) for t in TYPES)
    return (f" & {label} & {cells} & {_h(g['Elam'])} & {_h(g['Edel'])} "
            f"& {_s(g['share'])}\\\\")


def composition_table(d, label):
    windows = sorted(d["windows"], key=lambda w: w["horizon"])
    body = []
    for j, w in enumerate(windows):
        h = w["horizon"]
        body.append(f"\\multirow{{4}}{{*}}{{{h} yr}}")
        body.append(_grp_row("Population", w["population"]))
        body.append(_grp_row("1 completed spell", w["one_spell"]))
        body.append(_grp_row("2+ completed spells", w["two_spell"]) + "[3pt]")
        rat = w["ratio"]
        ratio_cells = " & ".join(f"\\textit{{{rat[t]:.2f}$\\times$}}" for t in TYPES)
        body.append(" & \\multicolumn{1}{l}{\\textit{Ratio (2+ spells / Pop.)}}\n"
                    f"   & {ratio_cells} & & & \\\\")
        if j < len(windows) - 1:
            body.append("\\midrule")
    body = "\n".join(body)

    return f"""% {d['country']} type composition by sample group and observation window
\\begin{{table}}[tbp]
\\centering
\\caption{{Type composition by sample group and observation window --- {d['country']}}}
\\label{{{label}}}
\\resizebox{{\\textwidth}}{{!}}{{
\\begin{{threeparttable}}
\\begin{{tabular}}{{llC{{1.2cm}}C{{1.2cm}}C{{1.2cm}}C{{1.2cm}}C{{1.6cm}}C{{1.6cm}}C{{1.2cm}}}}
\\toprule
Window & Group & HH & HL & LH & LL
       & $\\mathbb{{E}}[\\lambda]$ & $\\mathbb{{E}}[\\delta]$ & Share\\\\
\\midrule
{body}
\\bottomrule
\\end{{tabular}}
\\begin{{tablenotes}}[flushleft]\\footnotesize
\\item \\textit{{Notes:}} Type shares are $P(\\text{{type}} \\mid \\text{{group}})$ computed via
Bayes' rule from the estimated type distribution and type-specific bin probabilities.
$\\mathbb{{E}}[\\lambda]$ and $\\mathbb{{E}}[\\delta]$ are the group-conditional means of the
unstable and stable spell exit hazards. ``Share'' is the fraction of all workers
falling in each group at the given horizon. Hazard rates are per month.
\\end{{tablenotes}}
\\end{{threeparttable}}
}}
\\end{{table}}"""


def _dd_panel(d):
    rows = []
    for x in sorted(d["dd"], key=lambda r: r["horizon"]):
        dd = x["dd_share"]
        dd_str = f"$\\phantom{{-}}{dd:.3f}$" if dd >= 0 else f"${dd:.3f}$"
        rows.append(f"{x['horizon']:>2d} & {x['fast_cycler_share']:.2f} & {dd_str} \\\\")
    body = "\n".join(rows)
    return f"""{{\\bfseries {d['country']}}}\\\\[3pt]
\\begin{{tabular}}{{ccc}}
\\toprule
Horizon & Fast-cycler & Duration \\\\
(years) & share & dependence \\\\
\\midrule
{body}
\\bottomrule
\\end{{tabular}}"""


def dd_table(spain, germany):
    return f"""% Selection does not generate duration dependence
\\begin{{table}}[tbp]
\\centering
\\caption{{Selection does not generate duration dependence. Each row simulates the
two-completed-spell estimation sample at the given horizon, using the calibrated
type composition and \\emph{{exponential}} spells (zero duration dependence by
construction), and applies the ABS decomposition. ``Fast-cycler share'' is the
share of high-$\\lambda$ types in the simulated sample; ``Duration dependence'' is
the recovered $\\sigma^{{2}}_{{e}}/\\sigma^{{2}}_{{y}}$.}}
\\label{{tab:selection_dd}}
\\begin{{minipage}}[t]{{0.48\\textwidth}}
\\centering
{_dd_panel(spain)}
\\end{{minipage}}
\\hfill
\\begin{{minipage}}[t]{{0.48\\textwidth}}
\\centering
{_dd_panel(germany)}
\\end{{minipage}}
\\end{{table}}"""


def binshares_table(d, label):
    rows = []
    for w in sorted(d["bin_shares"], key=lambda x: x["horizon"]):
        s = w["shares"]
        rows.append(f"{w['year']}--{d['end_year']} & {w['horizon']:>2d} & "
                    + " & ".join(f"{x:.3f}" for x in s) + " \\\\")
    body = "\n".join(rows)
    return f"""% {d['country']} empirical bin shares by window
\\begin{{table}}[tbp]
\\centering
\\caption{{Empirical bin shares by observation window --- {d['country']}}}
\\label{{{label}}}
\\begin{{tabular}}{{lrrrrrr}}
\\toprule
Window & $T$ (yr) & Bin 0 & Bin 0.5 & Bin 1 & Bin 1.5 & Bin 2\\\\
\\midrule
{body}
\\bottomrule
\\end{{tabular}}
\\end{{table}}"""


def params_table(d, label):
    p = d["params"]
    def dur(x):
        return f"{1.0/x:.1f}" if x > 0 else "--"
    return f"""% {d['country']} parameter estimates
\\begin{{table}}[tbp]
\\centering
\\caption{{Parameter estimates --- {d['country']}}}
\\label{{{label}}}
\\begin{{tabular}}{{llrr}}
\\toprule
Parameter & & Estimate & Implied mean dur. (months)\\\\
\\midrule
$\\lambda_H$ & Unstable exit (H type) & {p['lam_H']:.4f} & {dur(p['lam_H'])}\\\\
$\\lambda_L$ & Unstable exit (L type) & {p['lam_L']:.4f} & {dur(p['lam_L'])}\\\\
$\\delta_H$  & Stable exit (H type)   & {p['delta_H']:.4f} & {dur(p['delta_H'])}\\\\
$\\delta_L$  & Stable exit (L type)   & {p['delta_L']:.4f} & {dur(p['delta_L'])}\\\\
\\midrule
$\\pi_{{HH}}$ & Fast cycler     & {p['pi_HH']:.3f} &\\\\
$\\pi_{{HL}}$ & Stable worker   & {p['pi_HL']:.3f} &\\\\
$\\pi_{{LH}}$ & Unstable worker & {p['pi_LH']:.3f} &\\\\
$\\pi_{{LL}}$ & Slow cycler     & {p['pi_LL']:.3f} &\\\\
\\bottomrule
\\end{{tabular}}
\\end{{table}}"""


def vdsim_table(d, label):
    rows = []
    for x in sorted(d["dd"], key=lambda r: r["horizon"]):
        rows.append(f"{x['horizon']:>2d} & {x['fast_cycler_share']:.2f} & "
                    f"{x['dd_share']:+.3f} & {x['het_share']:.3f} \\\\")
    body = "\n".join(rows)
    return f"""% {d['country']} variance decomposition in the simulated estimation sample
\\begin{{table}}[tbp]
\\centering
\\caption{{Variance decomposition in the simulated (zero-DD) estimation sample --- {d['country']}}}
\\label{{{label}}}
\\begin{{tabular}}{{rrrr}}
\\toprule
$T$ (yr) & High-$\\lambda$ share & DD share ($\\sigma_e^2/\\sigma_y^2$) & HT share ($\\sigma_b^2/\\sigma_y^2$)\\\\
\\midrule
{body}
\\bottomrule
\\end{{tabular}}
\\end{{table}}"""


def main():
    spain = _load("spain")
    germany = _load("germany")
    os.makedirs("tex", exist_ok=True)
    sections = [
        "% Sample-selection tables",
        "% Auto-generated by sample_selection_tables.py -- do not edit manually.",
        binshares_table(spain, "tab:binshares_spain"),
        binshares_table(germany, "tab:binshares_germany"),
        params_table(spain, "tab:params_spain"),
        params_table(germany, "tab:params_germany"),
        composition_table(spain, "tab:composition_spain"),
        composition_table(germany, "tab:composition_germany"),
        dd_table(spain, germany),
        vdsim_table(spain, "tab:vdsim_spain"),
        vdsim_table(germany, "tab:vdsim_germany"),
    ]
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n\n".join(sections) + "\n")
    n_tables = sum(1 for s in sections if s.startswith("%") is False or "\\begin{table}" in s)
    print(f"Saved sample-selection tables to {OUT}")


if __name__ == "__main__":
    main()
