# Claude Code Brief — Phase 3: Slimming the b/d Variant Scripts

This repo (`russia_sentiment_paper`) holds the analysis for "The Signaling Gap."
The manuscript lives on Overleaf, not here — never touch it. This brief is a
handoff from a prior session; everything it asserts was verified in that session
against code and disk, but **verify before relying on it** — that is the house
rule and it has caught real errors.

## Read first

1. `plan.md` at the repo root — the running state for the whole revision. The
   sections "Phase 3 — typology robustness", "Bootstrap replications raised to
   B = 99,999" and "Re-render queue" are the relevant ones.
2. `scripts/README.md` and `scripts/master.Rmd` for the pipeline shape.

## Pipeline as it stands

```
00_setup.R → 01 → 02 → 03A/03B
  → 04{a,b,d} H1 → 05{a,b,d} H2 → 06{a,b,d} H3a → 07{a,b,d} H3b
  → 08_bandwidth_sensitivity
  → 09_preperiod_diagnostics
  → 10{a,b,d}_publication_outputs
  → 11_typology_robustness
```

`a` = probabilistic time (primary), `b` = day running variable, `d` = drop
no-time articles.

## The task

Slim the eight variant scripts — `04{b,d}`, `05{b,d}`, `06{b,d}`, `07{b,d}` — so
they compute only what is still consumed, plus every figure. The `a` files are
**out of scope and must not be touched**.

Donald has archived the current versions to
`scripts/archive/alternative_specs_full/` (commit `129b5a3`), so the originals
are recoverable independently of git history.

### What must survive

**1. The objects below**, which the reconciled `10b`/`10d` main tables (Tables
1–5) consume. This list was computed by parsing `10b` after reconciliation.
Re-derive it rather than trusting it.

| Script | Objects to keep |
|---|---|
| `04{b,d}` | `model1_opt`, `model2_opt`, `model3_opt`, `model4_opt`, `model5_opt`, `model6a_nonmil`, `model7a_nonnato` |
| `05{b,d}` | `model2_state_rdd_z`, `model2_ind_rdd_z`, `model2a_opt_z`, `model2b_z`, `model2d_z`, `matched_model_z`, and the five by-topic models `model2a_opt_{pol,mil,econ,cult,oth}` |
| `06{b,d}` | `model5a_csto_z`, `model5a_neutral_z`, `model5a_opt_z`, `model5a_opt_non_mil_z`, `matched_model` |
| `07{b,d}` | `model6a_high_z`, `model6a_low_z`, `model6a_opt_z`, `model6a_opt_non_mil_z`, `matched_model_z` |

Their `bootstrap_se` entries must survive too — the tables' significance stars
come from the wild cluster bootstrap, not the analytic p-values.

`11_typology_robustness.Rmd` reads a strict subset of the above (`model5_opt`;
`model2d_z`, `matched_model_z`; `model5a_opt_non_mil_z`, `matched_model`;
`model6a_opt_non_mil_z`, `matched_model_z`), so keeping this list satisfies both
consumers.

**2. Every figure-producing chunk, in both `b` and `d`.** This is explicit:
Donald wants the two variants consistent and does not want to recreate any
figure later, including ones the paper never uses. Do not drop a figure because
it looks unused.

Three of the paper's figures are produced by `b` files, not `a` — day grouping
is what keeps their scatter legible:

- `figures/rdd/days/invasion_on_sentiment_non_mil.png` (04b)
- `figures/diff_in_disc/days/invasion_discs_non_mil.png` (05b)
- `figures/heterogeneity/days/state_align_discs.png` (06b)

Plus the `_labeled` variants of all three, and
`figures/diff_in_disc/days/neutral_floor_side_by_side.png`.

**3. `MatchIt` sections.** The matched models are half of what `11` compares and
are Table 2 Model 6 / Table 4 Model 5 / Table 5 Model 5. Matching is a runtime
cost that has to stay.

### What to remove

Everything reaching only the S-tables, which `10b`/`10d` will no longer build.
By family (verified against `10b`):

- **04{b,d}** (14 objects): `model1_basic`, `model1_country_fe`,
  `model1_country_source_fe`, `model1_full_linear`, `model1_z`,
  `model5_opt_{pol,mil,econ,cult,oth}`, `model6_non_mil`, `model7_non_nato`,
  `model_placebo`, `model_placebo_z`
- **05{b,d}** (21 objects): the leave-one-out loop and matched leave-one-out loop
  (`loo_summary`, `matched_loo_summary`), `model_placebo` and
  `optimal_bw_placebo`, the full-FE ladder (`model2a`, `model2a_full`,
  `model2a_opt`, `model2a_opt_full_fe`, `model2a_z`, `model2b`,
  `model2b_full_fe`, `model2d`), the by-topic full-data models
  `model2a_full_{pol,mil,econ,cult,oth}`, the Russian-related models
  (`model3a_opt`, `model3a_opt_full_fe`), `model_did`, and the unmatched
  `matched_model` (note: `matched_model_z` is kept, `matched_model` is not)
- **06{b,d}** (25 objects): the leave-one-out and matched leave-one-out loops,
  both placebos (`model_placebo_nonmil`, `optimal_bw_placebo_nonmil`,
  `placebo_aligned_models`), the by-topic models (`model5a_opt_*` and
  `model5a_full_*`), the FE ladder, `model5a_fully_saturated`, the Russian-only
  models, and the mini-regression `decomposition` block (~300 lines)
- **07{b,d}**: little to remove; it is already small

Also remove the `## Total Effect, Sentiment-Z (No FEs)` section from `06b` and
`06d`. It is serialized nowhere and consumed by nothing. **In `06a` the same
section duplicates the Task E `model5a_opt_z_total` specification** — same
residualization on `csto`, same bandwidth procedure, same formula. Verify that,
and if it holds, merge the two in `06a` rather than leaving both. `06a` is
otherwise out of scope; this is the one permitted exception, and it should be
its own commit. Within that section `model5_full_csto_z` uses `sentiment_z`
while `model5_total_neutral` uses `sentiment_clean` despite the heading.

Also drop the in-file summary tables at the end of `05b`/`05d` ("Table 2: Main
Results", "Table 2-S: Supplemental", the by-topic tables) — the publication
scripts own table building.

## Conventions

- **Read specifications from code, never assume.** Sample definitions vary; print
  the exact filter, outcome construction and FE structure of anything you touch.
- Reuse existing conventions: `here::here()`, `source("00_setup.R")`,
  `set.seed(3184)`, the `FIGURES_*` path constants, `save_table()`, the dashed
  Feb-24 figure line.
- **Annotate and outline.** Every surviving chunk keeps a markdown heading and a
  prose sentence above it, matching the density of the surrounding code. When a
  section is removed, do not leave an orphaned heading.
- Reader-facing text uses **"Russia-aligned"**, never "CSTO". Internal variable
  names stay.
- **One commit per file family**, descriptive message. Donald pushes. Never
  bundle families.
- **Never render `master.Rmd`** — the full pipeline is ~4 hours and re-runs
  01–03, which exist only for replication. `data/intermediate/02_*.rds` are
  present; load those.

## Verification, required before each commit

1. `knitr::purl()` the edited file and `parse()` the result — this catches both R
   syntax errors and duplicate chunk labels. A duplicate label made `05a`
   unknittable for some time before it was caught.
2. Confirm every object in the keep list is still assigned **and still in the
   serialization list** at the end of the script.
3. Confirm no dropped object is still referenced anywhere in the file.
4. Confirm the figure `ggsave()` calls are unchanged in count and destination.
5. **Check the exit code of every R run.** A prior session missed a script that
   aborted partway because it grepped the log instead of checking the exit
   status; the CSVs looked current while the summary file was stale.

R lives at `C:\Program Files\R\R-4.5.3\bin\Rscript.exe`. Run from `scripts/`.

## Re-rendering

Slimming changes what the `.rds` files contain, so `05{b,d}` and `06{b,d}` must
be re-rendered for `10b`/`10d`/`11` to work against them. Two independent reasons
to re-render already exist, recorded in `plan.md`:

- `dqrng` is now seeded in `00_setup.R`, so all previously generated bootstrap
  p-values are superseded.
- `B` was raised from 4,999 to 99,999.

Additionally **two `.rds` files are stale and predate their scripts**:
`04_h1_results_drop.rds` and `07_ethnic_results_drop.rds` (serialized
2026-03-04). They are missing `model5_opt` and
`model6a_opt_non_mil_z`/`matched_model_z` respectively, which is why three cells
in `table_s16` are currently empty. Re-rendering `04d` and `07d` fills them.

Attempt the re-renders. If they fail or run too long, deliver ready-to-run code
and tell Donald exactly what to run.

## Honest failure

If a strand is not working, stop, revert to the last commit, and report it
precisely. Do not leave a half-slimmed file. Never report success from a grep —
verify the artifact.

## Open question for Donald

After slimming, `10b`/`10d` will still contain their S-table chunks, which
reference objects that no longer exist. Ask whether to (a) strip the S-table
chunks from `10b`/`10d` so they build only Tables 1–5, or (b) archive `10b`/`10d`
outright now that `11` supersedes them. Donald has said he intends to archive
them; confirm the timing before leaving the repo in a state where those scripts
would error.
