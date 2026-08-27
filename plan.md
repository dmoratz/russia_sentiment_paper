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
| **D** | **DONE** | `00_setup.R`, `05a`, `06a`, `09a` | country-clustered WCR for 4 models; side-by-side txt + CSV; explicit point-estimate identity check |
| **E** | **DONE** | `04a`, `05a`, `06a`, `09a` | `model5_opt_total`, `model2a_opt_z_total`, `model5a_opt_z_total`; `table_s14`; total-vs-headline comparison CSV |
| **F** | **DONE** | `05a`, `05b` | neutral state-owned vs independent floor figure, both variants |
| **G** | **DONE** | new `10_preperiod_diagnostics.Rmd` | pre-period topic demeaning; pre-period-only z; topic-mapping diagnostic. Not registered in `master.Rmd` |
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

### Task D — country-level clustering check — DONE

**Method.** Serialized `fixest` objects cannot be re-bootstrapped: `fixest` fetches
the estimation data from the environment where the fit happened, and that is gone
once the object has been through `saveRDS`. So the runner replays 05a and 06a from
`02_*.rds` with `run_wild_bootstrap()` and `ggsave()` stubbed out, rebuilds the four
models with the host scripts' own code, and bootstraps those.

Two consequences worth recording:

- Both replays **abort partway**, in the `sensemakr` sensitivity chunk, because the
  stub returns an `NA` SE and `adjusted_estimate()` rejects it. That chunk runs
  strictly *after* every object Task D needs. Correctness therefore does not rest on
  the replay completing — it rests on the identity check below.
- The exact-matching in both files is `method = "exact"`, i.e. deterministic, so the
  matched samples reproduce without any RNG concern.

**Point-estimate identity: verified, all four exact.** Clustering changes inference
only, so this is the check that the sample and spec did not silently move:

| Model | Headline | Refit | Refit + droplevels | max abs diff |
|---|---|---|---|---|
| H2 headline (`model2a_opt_z`) | 0.0797099 | 0.0797099 | 0.0797099 | 0 |
| H2 matched (`matched_model_z`) | 0.2222964 | 0.2222964 | 0.2222964 | 0 |
| H3a headline (`model5a_opt_z`) | -0.1926311 | -0.1926311 | -0.1926311 | 0 |
| H3a matched (`matched_model`) | -0.3803738 | -0.3803738 | -0.3803738 | 0 |

**The known WCR incompatibility, diagnosed rather than worked around.**
`boottest()` fails with `length(g) must match length(x)` when the clustering
variable is a factor carrying levels with **no observations**. 06a does not
`droplevels()` after its bandwidth filter (05a does), so its non-NATO samples still
declare all 12 countries while using 8 — which is exactly why country clustering
failed for H3a and succeeded for H2. Dropping unused levels fixes it and cannot move
the estimate, because `country` appears in neither the formula nor the fixed
effects; the third column of the table above is the evidence, and the same
assertion is baked into the chunks as `stopifnot()`.

**Results** (WCR, Webb six-point weights, null imposed, fnw11, B = 4999):

| Model | Estimate | N | Source clusters | Source p | Source 95% CI | Country clusters | Country p | Country 95% CI |
|---|---|---|---|---|---|---|---|---|
| H2 headline | 0.0797 | 40,710 | 60 | 0.2597 | [-0.0891, 0.2102] | 11 | 0.1580 | [-0.0586, 0.1746] |
| H2 matched | 0.2223 | 31,379 | 43 | 0.0298 | [0.0333, 0.3604] | 8 | 0.0248 | [0.0340, 0.3134] |
| H3a headline | -0.1926 | 7,164 | 13 | 0.2531 | [-0.4843, 0.1093] | 8 | 0.2741 | [-0.5251, 0.1355] |
| H3a matched | -0.3804 | 5,721 | 13 | 0.0256 | [-0.7596, -0.0534] | 8 | 0.0328 | [-0.8109, -0.0378] |

**Reading.** No conclusion changes. Both matched RDIDs stay significant at the 5%
level under country clustering (H2 0.0298 → 0.0248, H3a 0.0256 → 0.0328) and both
headline interactions stay null. Cluster counts match the brief's expectation for
the two optimal-bandwidth models (H2 = 11, H3a = 8). The H2 **matched** model has 8
country clusters rather than 11, because it is fit on the non-NATO sample — flagged
in advance, and now confirmed.

**Incidental bug found and fixed separately** (commit `Fix duplicate chunk labels in
05a`): 05a reused the chunk labels `state-only-rdd-prob` and `ind-only-rdd-prob` for
its z-score chunks, which made the file **unknittable** — `knitr` aborts on duplicate
labels, so 05a could not be rendered or purled at all. A sweep of every `.Rmd` in
`scripts/` found no other file affected.

### Task E — total-effect columns — DONE

A new estimand, not a robustness check: the headline specifications condition on
topic and so identify the shift in sentiment *within* topics, while the total effect
lets the topic mix move as well, which is what a reader of these outlets actually
experiences.

Built by cloning each headline and removing only the topic adjustment. "Model 5" was
unambiguous in code — 04a carries a literal `## Model 5: Z-Score Model (Topic FE)`
heading — so the three bases are `model5_opt` (04a, rdrobust with topic dummies as
`covs`), `model2a_opt_z` (05a) and `model5a_opt_z` (06a). Sample, source-level
z-scored outcome and source clustering are unchanged; all articles are used,
military included.

**Bandwidth re-selected**, per the decision above: the same mserd/triangular/
source-clustered `rdbwselect`, with topic dropped from the residualization so the
bandwidth stays MSE-optimal for the specification actually being fit. For H1 the
selection is internal to `rdrobust`.

**All three headline siblings reproduce exactly** before the new estimand is
reported (|diff| = 0 against `04_h1_results_prob.rds`, `05_h2_results_prob.rds`,
`06_alignment_results_prob.rds`).

| Spec | Term | Headline | Total | Δ | Bandwidth (headline → total) | N (headline → total) |
|---|---|---|---|---|---|---|
| H1 | Invasion | -0.2172 (SE 0.0362) | **-0.2398** (SE 0.0346) | -0.0226 (+10%) | 24.65 → 24.68 d | 45,366 → 45,398 |
| H2 | State-Owned × Treat | 0.0797 (boot SE 0.0633, p 0.246) | **0.0965** (boot SE 0.0584, p 0.144) | +0.0168 (+21%) | 20.93 → 24.59 d | 40,710 → 45,304 |
| H3a | Russia-Aligned × Treat | -0.1926 (boot SE 0.1110, p 0.255) | **-0.2218** (boot SE 0.1219, p 0.219) | -0.0292 (+15%) | 38.42 → 37.01 d | 7,164 → 6,999 |

**Reading.** Every total effect is larger in magnitude than its headline, so
including topic reallocation strengthens rather than weakens the pattern. H1 remains
strongly significant. Both interactions remain null on the bootstrap p-values the
paper reports, though H3a's total effect reaches the 10% analytic threshold. This
sits consistently with Task G section (i), which found that freezing the topic
adjustment at pre-invasion values barely moves anything — the topic mix contributes
a modest amount in a consistent direction rather than driving the results.

*Presentation note:* `modelsummary`'s `Num.Obs.` reports the full sample for
`rdrobust` but the bandwidth-restricted sample for `feols`, which would have put two
different quantities on one row of a table mixing both. `Num.Obs.` is omitted and an
explicit `N (within bandwidth)` row is added instead.

### Task F — neutral-media floor figure — DONE

Two panels on a shared colour legend, `theme_classic()`, date granularity:

- **Panel A** places both media types on the **full coding scale**. The sentiment
  variable is a three-point code taking values in {-1, 0, 1}, so the floor is a hard
  -1 and is drawn on the figure. Daily means are plotted with the pre- and
  post-period means overlaid as horizontal segments, dashed line at Feb 24.
- **Panel B** zooms to the four period means with 95% CIs, labels each level, and
  boxes the pre-to-post change so magnitudes are readable.

**The numbers that make the argument** (neutral countries: Georgia, Kosovo, Moldova,
Serbia; all articles):

| Media type | Pre-invasion | Post-invasion | Change | N pre / post |
|---|---|---|---|---|
| State-owned | -0.259 | -0.263 | **-0.005** | 2,308 / 4,008 |
| Independent | -0.228 | -0.357 | **-0.129** | 10,247 / 35,259 |

Neutral state media start at -0.26 — close to independent media's -0.23, and a long
way above the -1 floor — and then do not move, while independent media in the same
countries and window fall by 0.13. So the null is not a floor or measurement
artifact: there was ample room to fall.

> **Worth knowing.** This figure uses only `date_publish` and `treatment` and no
> running variable at all, so the `05a` and `05b` versions are **identical in
> content**; only the output directory and the variant label in the title differ.
> Both were built as agreed, and both were verified to produce the same means. If
> the b/d retirement in Phase 3 happens, the `05b` copy is the one to drop.

### Task G — pre-period adjustment diagnostics — DONE

Built as `scripts/10_preperiod_diagnostics.Rmd`, assembled by copying the estimation
machinery out of 04a/05a/06a rather than writing new estimators; every copied block
carries a `# Following <file>, chunk <name>` comment. **Deliberately not registered
in `master.Rmd`** (verified: zero references), per the brief. Bootstrap runs at the
repository default `B = 4999` — not reduced. Runs end-to-end in about two minutes.

**Headline reproduction cross-validated.** The script recomputes each headline and
matches the serialized objects; the H2 and H3a values it reports (0.0797099 and
-0.1926311) are the same ones Task D independently verified against
`05_h2_results_prob.rds` / `06_alignment_results_prob.rds`.

**(i) Topic adjustment frozen at pre-invasion values.** Nothing moves by even half a
headline standard error:

| Spec | Scale | Headline | Diagnostic | Δ | Δ in headline SEs |
|---|---|---|---|---|---|
| H1 | z | -0.2172 | -0.2221 | -0.0049 | -0.14 |
| H2 | z | 0.0797 | 0.1014 | +0.0217 | +0.34 |
| H3a | z | -0.1926 | -0.2087 | -0.0161 | -0.15 |
| H1 | raw | -0.1153 | -0.1175 | -0.0023 | -0.11 |
| H2 | raw | 0.0323 | 0.0460 | +0.0137 | +0.41 |
| H3a | raw | -0.1074 | -0.1207 | -0.0133 | -0.25 |

The large `pct_change` figures for H2 (27%, 42%) are an artefact of a near-zero
denominator, not a meaningful shift.

*Ambiguity resolved by reporting both scales:* the brief says to demean
`sentiment_clean`, but all three named headlines have `sentiment_z` as the outcome,
so the literal instruction would compare a raw-unit estimate against a z-unit
baseline. Both scales are computed, and the raw-scale headline siblings (04a
`model2_opt`, 05a `model2a_opt`, 06a `model5a_opt`) are recomputed so every row has a
like-for-like baseline. The raw rows are the literal reading of the brief.

**(ii) Pre-period-only z-scoring.** All three estimates grow in magnitude, as the
mechanics predict (pre-period SD < full-window SD):

| Spec | Headline | Diagnostic | Δ | SE ratio | Headline p | Diagnostic p (bootstrap p) | Sources dropped |
|---|---|---|---|---|---|---|---|
| H1 | -0.2172 | -0.2418 | -0.0246 | 1.17 | 1.96e-09 | 1.28e-08 | 2 |
| H2 | 0.0797 | 0.1096 | +0.0299 | 1.07 | 0.213 | 0.110 (0.159) | 1 |
| H3a | -0.1926 | -0.2545 | -0.0619 | 0.96 | 0.108 | **0.034** (0.100) | 0 |

> **Flag for Donald.** Under pre-period-only z-scoring, H3a's *analytic* p crosses
> 0.05 (-0.2545, p = 0.034) while its *wild-bootstrap* p stays at 0.100. The paper
> reports bootstrap p-values, so the reported inference does not cross — but the
> sensitivity is worth knowing about.

Dropped sources: `voceabasarabiei.md` (no pre-invasion articles; H1 and H2) and
`insajder.net` (pre-invasion SD = 0 across 2 articles; H1 only — H2's existing
`sd > 0` filter had already removed it).

**(iii) Topic-mapping diagnostic.** Every topic's mean falls across the cutoff, but
by very different amounts, and topic shares move too. In the H2 headline-bandwidth
window: Culture -0.445, Military -0.400, Economic -0.317, Other -0.195, Political
-0.183 (z units), while Political's share of coverage drops 48% → 34% and Military's
rises 23% → 30%. The `fe_vs_pre_mean_gap` column spans -0.10 to +0.10 (H2) and -0.11
to +0.13 (H3a). So the mappings genuinely do move; section (i) shows the movements
largely cancel in the difference-in-discontinuities.

**Limitation recorded honestly:** H1's headline is `rdrobust`, which drops one topic
dummy for collinearity **without reporting which one**, so its `beta_covs` (4 values
for 5 dummies) cannot be mapped back to topic names. The topic-FE columns are `NA`
for H1 in the mapping table and `beta_covs` is printed unlabelled with that caveat.
`fixef()` is used for H2/H3a as intended.

Also confirmed by the build: `treatment` and `running_probabilistic < 0` agree on
every article in all three samples (0 disagreements), and H1's running variable is in
**seconds** (04a never divides by 86400) while H2/H3a are in days — hence H1's
bandwidths printing as ~2.1e6. That is pre-existing 04a behaviour, preserved.

## Re-render queue (for Donald, at leisure)

Re-render these so the `.rds` files are once again a clean product of their host
script, rather than a patched version. Nothing depends on this being done soon —
the patched objects reproduce exactly (see Task B above).

- `06a_russian_alignment_analysis_prob.Rmd` — adds `placebo_aligned_pooled`,
  `placebo_aligned_pooled_cl`, `placebo_aligned_estimates` (Task B) and
  `country_cluster_check` (Task D) to `06_alignment_results_prob.rds`.
- `05a_diff_in_disc_analysis_prob.Rmd` — adds `country_cluster_check` (Task D) and
  `model2a_opt_z_total`, `optimal_bw_total`, `bootstrap_se$model2a_opt_z_total`
  (Task E) to `05_h2_results_prob.rds`.
- `04a_main_rdd_analysis_prob.Rmd` — adds `model5_opt_total` to
  `04_h1_results_prob.rds` (Task E). 06a additionally gains
  `model5a_opt_z_total`, `optimal_bw_align_total` and its bootstrap (Task E).

## Output manifest

**Task F**

- `figures/diff_in_disc/prob/neutral_floor_side_by_side.png`
- `figures/diff_in_disc/days/neutral_floor_side_by_side.png` (identical content)

**Task E**

- `figures/tables/prob/table_s14_total_effect.tex` — appendix table, headline and
  total columns paired for H1, H2, H3a
- `figures/tables/prob/table_s14_total_effect.html`
- `figures/tables/prob/total_effect_comparison.csv` — estimates, SEs, N, bandwidth

**Task G** (author diagnostics, not paper outputs)

- `output/diagnostics/preperiod_topic_demeaned_comparison.csv`
- `output/diagnostics/preperiod_zscore_comparison.csv`
- `output/diagnostics/preperiod_zscore_dropped_sources.csv`
- `output/diagnostics/topic_mapping_diagnostic.csv`
- `output/diagnostics/preperiod_diagnostics_summary.txt`
- `output/10_preperiod_diagnostics.html` (rendered report; gitignored)

**Task D**

- `figures/tables/prob/country_clustering_comparison.csv` — full side-by-side
- `figures/tables/prob/country_clustering_comparison.txt` — printed side-by-side
- `figures/tables/prob/country_clustering_identity_check.csv` — point-estimate
  identity evidence

**Task B / A1**

- `figures/tables/prob/table_s13_placebo_aligned.tex` — appendix table, five columns
  (four countries + pooled)
- `figures/tables/prob/table_s13_placebo_aligned.html`
- `figures/tables/prob/placebo_aligned_estimates.csv` — tidy per-country + pooled
  estimates, both pooled variances
- `figures/heterogeneity/prob/pretrend_slopes_aligned.csv` — per-country pre-invasion
  slopes (A1)
