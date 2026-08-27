# Signaling Gap Revision — Execution Plan

Running state for the v3 revision brief
(`plans/claude_code_brief_rough_draft_v3_robustness_updates.md`).
Updated at every commit. Status legend: `TODO` / `WIP` / `DONE` / `BLOCKED` / `SKIPPED`.

## Conventions in force

- **Prob-only**, except Task C (`b` variants, by design) and the `05b` half of Task F
  (Donald's explicit call — see Decisions).
- Reader-facing group label is **"Russia-aligned"**, never "CSTO"/"Non-CSTO".
  Internal variable names (`csto`, `CSTO_COUNTRIES`) are unchanged.
- Figures at **date** granularity even where estimation is date-time.
- Existing conventions reused throughout: `here::here()`, `set.seed(3184)`,
  `save_table()`, the `FIGURES_*` path constants from `00_setup.R`, the dashed
  Feb-24 line, modelsummary/gt styling. No new conventions introduced.
- New code is **annotated and outlined**: every new chunk sits under a markdown
  heading matching the host file's existing outline depth, with a prose sentence
  describing what the chunk does and why, as the surrounding chunks do.
- Task G is assembled by **copying machinery from 04a/05a/06a**, not by writing
  fresh estimation code. The custom bandwidth/bootstrap/sample-construction code
  in those files is the point of the exercise.
- One commit per task. Donald pushes. Tasks are never bundled.
- **Text/CSV output locations.** The repo had no pre-existing CSV/TXT output
  convention (no `.csv` or `.txt` anywhere under `figures/`), so the minimal rule
  adopted here is: a summary file lives beside the object it describes.
  Figure-tied summaries → `figures/heterogeneity/prob/`; table-tied summaries →
  `figures/tables/prob/`; author-only diagnostics that are not paper outputs
  (Task G) → `output/diagnostics/`.

## Execution strategy

`master.Rmd` is **never** rendered (~4 h, re-runs 01-03 which exist only for
replication). All `data/intermediate/02_*.rds` are present in this clone, so
targeted execution is viable.

For each task: the canonical chunk is added to its host `.Rmd` **and** a targeted
runner script (scratchpad) loads `02_*.rds`, re-derives the sample exactly as the
host script does up to that point, computes only the new objects, and writes
outputs to their established locations. Where `09a` needs a new object, the runner
appends it to the existing `*_results_prob.rds`.

> **Recorded trade-off.** A patched `.rds` is not byte-identical to a clean render
> of its host script. Scripts to re-render at leisure so the `.rds` files are once
> again a clean product of their host are listed under "Re-render queue" below.

---

## PHASE 0 — Audit — **DONE**

### A1. Pre-trend figures — VERIFIED, one gap

Both figures are built in `scripts/06a_russian_alignment_analysis_prob.Rmd`
(chunks `pretrend-by-country-aligned-prob` L144, `pretrend-by-country-aligned-dec-prob`
L217). The READMEs' `06C_russian_alignment_analysis_prob.Rmd` is a stale name.

Documented spec confirmed against code: `data` filtered to `CSTO_COUNTRIES` and
`state_owned == 1`; daily mean `sentiment_clean` per country; `facet_wrap(~ country)`;
dotted grey Dec-7 line, dashed Feb-24 line; `geom_smooth(method = "lm")` fit on the
pre-invasion subset only; windows `2021-06-01` and `2021-12-01`, both ending
`2022-06-01`. Ukraine is excluded upstream (it is in `NATO_COUNTRIES`). Both PNGs are
on disk in `figures/heterogeneity/prob/`.

**Gap:** chunk `pretrend-slopes-aligned-prob` (L190) computes per-country pre-invasion
slopes but only `print()`s them. Needs a file write. Folded into the Task B commit.

### A2. Aligned placebo objects — VERIFIED as documented

`placebo_aligned_models` is built at `06a` L1002 (chunk `placebo-dec-aligned-prob`)
and serialized at L2158 into `06_alignment_results_prob.rds`.

Spec confirmed: loop over `CSTO_COUNTRIES`; `state_owned == 1`,
`!topic_clean %in% "Military"`, `date_publish < "2022-02-19"`; running variable
recentred on `2021-12-07 00:00:00 UTC` and rescaled to days; source-level z-score
computed **within** each country's subset; `rdrobust` with topic dummies passed as
`covs` and **no** `cluster` argument, i.e. rdrobust's default nearest-neighbour
HC variance. Matches the README.

The `table-s13` chunk exists in the publication script at L1295 and calls
`save_table(table_s13, "table_s13_placebo_aligned", TABLE_SUBDIR)`.
**No `table_s13_placebo_aligned.tex` or `.html` exists on disk** — confirming the
brief: the code was written but never run.

### A3. Pooled aligned-group placebo — DOES NOT EXIST

`09_bandwidth_sensitivity.Rmd` contains no placebo code at all (grep for
`placebo|Dec|2021-12-07|aligned` returns nothing).

The nearest existing object is `06a` L957 (`placebo-dec-nonmil-prob`) →
`model_placebo_nonmil`:
`feols(sentiment_z ~ running_probabilistic * treatment * csto | topic_clean,
cluster = ~source_domain)` on `data_align_state_non_mil`. That is a **difference-in-
discontinuities** placebo testing aligned *versus* neutral state media, not a pooled
aligned-only level discontinuity.

**Consequence: Task B must build the pooled estimate.**

### A4. Stale references (corrected in Phase 1)

Root `README.md`:
- `06C_russian_alignment_analysis_prob.Rmd` and bare `06C` — 5 occurrences in the
  "Pre-Trend Robustness" section → `06a_russian_alignment_analysis_prob.Rmd`.
- `08a_publication_outputs.Rmd` → `09a_publication_outputs_prob.Rmd` (post-renumber).
- Outputs section lists `figures/table_1.html`, `table_2.html`, `table_3.html` —
  **these do not exist**. Actual: `figures/tables/prob/table_01_main.{tex,html}`,
  `table_02_main.*`, `table_03_main.*`.
- Outputs section lists `figures/invasion_on_sentiment.png`,
  `figures/invasion_discs_graph.png`, `figures/articles_per_day.png` at the `figures/`
  root — all actually live in per-variant subdirectories.
- Pipeline table rows for steps 8 and 9 need the renumber.

`scripts/README.md`:
- Same `06C` (4 occurrences) and `08a_publication_outputs.Rmd` references in the
  "Pre-Trend Robustness Outputs" table.
- File-descriptions table and the ASCII pipeline diagram need the 08/09 renumber.

### A5. Canonical figure builders — VERIFIED, with a caveat

Variants avoid collision by **output subdirectory** (`FIGURES_*_{DAYS,PROB,DROP}`
from `00_setup.R` L111-129), not by filename. Some scripts add a redundant filename
suffix; the practice is inconsistent.

| Canonical path | Written by | Prob counterpart |
|---|---|---|
| `figures/rdd/days/invasion_on_sentiment_non_mil.png` | `04b` L852 | `figures/rdd/prob/invasion_on_sentiment_non_mil.png` (`04a` L813) — **same basename** |
| `figures/diff_in_disc/days/invasion_discs_non_mil.png` | `05b` L592 | `05a` L488 writes `invasion_discs_non_mil_prob.png` |
| `figures/heterogeneity/days/state_align_discs.png` | `06b` L140 | `06a` writes `state_align_discs_prob.png` |

Two of the three exact filenames exist only under `days/`, matching the brief. The
H1 figure exists under **both** `rdd/days/` and `rdd/prob/` with the same basename, so
filenames alone could not settle it. **Donald confirmed the paper uses the `days`
(`04b`) version**, consistent with the other two. Task C therefore targets
`04b` / `05b` / `06b`.

### Additional finding — Task F anchor is in the `b` variant

`invasion_discs_graph_neutral.png` is built at **`05b` L171** (chunk
`plot-discs-neutral`), the days variant. `05a` has **no neutral section at all**
(zero matches for `neutral`). Raised with Donald; see Decisions.

### Phase 1 safety check — VERIFIED

`09_bandwidth_sensitivity.Rmd` reads only `02_cleaned_data.rds` and
`02_data_non_ukraine.rds` (L40-41). It has no dependency on any 04-07 output, so
moving it ahead of the publication scripts is safe.

### Environment

`Rscript.exe` at `C:\Program Files\R\R-4.5.3\bin\`. All `data/intermediate/02_*.rds`
are present. Targeted execution is viable; code-only delivery is the fallback, not
the expected path.

---

## Decisions taken with Donald (pre-execution)

1. **Task F location — both.** Build the floor figure in `05a` (new neutral section,
   prob) *and* in `05b` (beside the existing `plot-discs-neutral` chunk).
2. **Task E bandwidth — re-select.** Run the same mserd / triangular /
   source-clustered `rdbwselect`, residualizing on the total-effect spec (topic
   dropped). Bandwidth will differ from the headline; that is intended. For H1 the
   selection is internal to `rdrobust`.
3. **Task D scope — headline + matched.** `model2a_opt_z` and `matched_model_z`
   (`05a`); `model5a_opt_z` and `matched_model` (`06a`).
4. **Task C target — `days` variant.** `04b`, `05b`, `06b`.
5. **Subagent escalation.** Any subagent hitting a spec ambiguity, a package
   conflict, or a result that does not match its stated expectation stops and
   surfaces it for review rather than working around it.

Note on (3): the H2 matched model is fit on `optimal_bandwidth_data_non_nato`, so its
country-cluster count is below the ~11 the brief anticipates. Actual counts are
reported per model rather than assumed.

---

## PHASE 1 — Renumber + documentation fix — **DONE**

- [x] `git mv scripts/08{a,b,d}_publication_outputs_* → scripts/09{a,b,d}_...`
- [x] `git mv scripts/09_bandwidth_sensitivity.Rmd → scripts/08_bandwidth_sensitivity.Rmd`
- [x] YAML `title:` fields in all four renamed files
- [x] `master.Rmd`: `pipeline_scripts` order, file-descriptions table, and the three
      prose sentences that named the old ordering
- [x] Root `README.md`: A4 corrections + renumber. Replaced the nonexistent
      `figures/table_{1,2,3}.html` list with the real `figures/tables/prob/table_0*_main.*`
      paths, and the root-level figure paths with their real per-variant subdirectories
- [x] `scripts/README.md`: A4 corrections + renumber + ASCII diagram + the "04–08 has
      three variants" sentence, which was wrong now that 08 is a single script
- [x] Internal cross-references: all eight `# Following ...` provenance comments in
      `08_bandwidth_sensitivity.Rmd` used retired names (old `C` suffix for the prob
      files, old unsuffixed names for the day files); corrected to `04a`–`07a` / `04b`–`07b`

Repo-wide sweep for `06C_russian`, `08{a,b,d}_publication_outputs`, and
`09_bandwidth_sensitivity` outside `scripts/archive/` returns nothing.

## PHASE 2 — Additions — TODO

| Task | Status | Host files | Deliverables |
|---|---|---|---|
| A1 fix | **DONE** | `06a` | slopes → `figures/heterogeneity/prob/pretrend_slopes_aligned.csv` (shipped with B) |
| **B** | **DONE** | `06a`, `09a` | pooled aligned Dec-7 placebo (`placebo_aligned_pooled`); `table_s13_placebo_aligned.{tex,html}`; pooled + per-country est/CI/p/bw/N CSV |
| **D** | TODO | `05a`, `06a` | country-clustered WCR for 4 models; side-by-side txt + CSV; explicit point-estimate identity check |
| **E** | TODO | `04a`, `05a`, `06a`, `09a` | `model5_opt_total`, `model2a_opt_z_total`, `model5a_opt_z_total`; `table_s14`; total-vs-headline comparison CSV |
| **F** | TODO | `05a`, `05b` | neutral state-owned vs independent floor figure, both variants |
| **G** | TODO | new `10_preperiod_diagnostics.Rmd` | pre-period topic demeaning; pre-period-only z; topic-mapping diagnostic. Not registered in `master.Rmd` |
| **C** | TODO (optional, last) | `04b`, `05b`, `06b` | direct series labels, new suffixed filenames only |

Serialization: F and C both touch `05b` — F first, C last. B / D / E fan out across
`04a` / `05a` / `06a` where independent.

## PHASE 3 — DEFERRED, not executed

Observations bearing on a future retirement of the `b`/`d` clones:

- The `05b` half of Task F and all of Task C are work a `b`-retirement would discard.
  Both were authorized with that known.
- All three canonical discontinuity PNGs the paper uses are produced by `b` files
  (A5). A thin typology-robustness replacement must either keep those figure chunks
  or move them into the `a` files first, or the paper loses its figures.

## Task results

### Task B — aligned placebo table — DONE

**Reproduction check passed exactly.** The runner recomputed the four per-country
placebos from `02_cleaned_data.rds` and compared them to the objects already
serialized in `06_alignment_results_prob.rds`: `|diff| = 0.00e+00` for all four
(Armenia, Azerbaijan, Belarus, Kazakhstan). The sample construction in the runner is
therefore identical to what 06a produces, which is what licenses patching the pooled
objects into the existing `.rds` rather than re-rendering 06a.

**Estimates** (Dec 7, 2021 false cutoff; state-owned, non-military, pre-invasion;
source-level z-scored outcome; rdrobust MSE-optimal bandwidth):

| Group | Sources | Estimate | SE | 95% CI | p | BW (days) | N |
|---|---|---|---|---|---|---|---|
| Armenia | 2 | 0.095 | 0.223 | [-0.343, 0.533] | 0.669 | 21.8 | 325 |
| Azerbaijan | 2 | -0.163 | 0.143 | [-0.444, 0.117] | 0.254 | 18.7 | 325 |
| Belarus | 3 | 0.320 | 0.143 | [0.040, 0.599] | **0.025** | 20.9 | 825 |
| Kazakhstan | 2 | -0.172 | 0.265 | [-0.692, 0.349] | 0.518 | 19.5 | 128 |
| **Pooled (HC)** | 9 | 0.108 | 0.089 | [-0.066, 0.282] | 0.225 | 27.9 | 2,061 |
| Pooled (source-clustered) | 9 | 0.153 | 0.087 | [-0.018, 0.324] | 0.080 | 23.7 | 1,835 |

**Two things for Donald to note.**

1. The pooled placebo is null (p = 0.225 HC; p = 0.080 clustered), which is the
   result the reviewer response wants: no pre-invasion jump at the warning date for
   the Russia-aligned group as a whole.
2. **Belarus is individually significant at p = 0.025, and the sign is positive**
   (+0.32). The reviewer concern was that sentiment may have turned *negative*
   during the buildup; a positive discontinuity is the opposite direction, so this
   does not support the concern — but it is a significant pre-period discontinuity
   and should be addressed in the text rather than left for a reader to find. Note
   also that the pooled point estimate (+0.11) is pulled upward by Belarus, which
   contributes 825 of the 2,061 pooled observations.

**Pre-invasion slopes** (A1 fix, now written to
`figures/heterogeneity/prob/pretrend_slopes_aligned.csv`): Armenia
-0.017/30d (p = 0.017), Azerbaijan +0.024/30d (p = 0.001), Belarus +0.001/30d
(p = 0.815), Kazakhstan -0.0002/30d (p = 0.978). Two of four are individually
significant and they point in **opposite directions**, which is consistent with no
common pre-invasion drift.

Incidental: `rdrobust` emits "Multicollinearity issue detected in covs. Redundant
covariates dropped." on both the per-country and pooled fits. This is pre-existing
behaviour of the per-country chunk (collinear topic dummies after `droplevels`), not
something introduced here.

## Re-render queue (for Donald, at leisure)

Re-render these so the `.rds` files are once again a clean product of their host
script, rather than a patched version. Nothing depends on this being done soon —
the patched objects reproduce exactly (see Task B above).

- `06a_russian_alignment_analysis_prob.Rmd` — adds `placebo_aligned_pooled`,
  `placebo_aligned_pooled_cl`, `placebo_aligned_estimates` to
  `06_alignment_results_prob.rds` by a clean run (Task B).

## Output manifest

**Task B / A1**

- `figures/tables/prob/table_s13_placebo_aligned.tex` — appendix table, five columns
  (four countries + pooled)
- `figures/tables/prob/table_s13_placebo_aligned.html`
- `figures/tables/prob/placebo_aligned_estimates.csv` — tidy per-country + pooled
  estimates, both pooled variances
- `figures/heterogeneity/prob/pretrend_slopes_aligned.csv` — per-country pre-invasion
  slopes (A1)
