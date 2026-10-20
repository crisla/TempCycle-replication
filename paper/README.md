# Paper source

Deliberately empty for now — the manuscript is still being written and will be
added here before submission.

What belongs here when it is ready:

- `SoalikeSodifferent.tex` — the manuscript
- `derivation_survival_functions.tex`, `derivation_truncation_bias.tex` —
  analytical appendices
- `sample_selection_note.tex`
- the bibliography, and any hand-drawn figures the manuscript includes that are
  not produced by code (the spell-definition and spell-selection schematics)

The generated tables the manuscript uses are written to `../output/tables/` by
`python run_all.py`. At present the manuscript hard-codes its tables inline
rather than pulling them in with `\input{}`; switching to `\input{}` would let a
reader confirm that the printed numbers are the ones this code produces.
