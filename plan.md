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

> Note: this section records the **first** renumber (08↔09). A later pass moved the
> publication scripts again, to `10{a,b,d}`, and promoted the diagnostics script to
> `09_`. See "Second renumber" below. File names quoted in this section are as they
> stood after Phase 1, not as they stand now.

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
| **E** | **SUPERSEDED by E3** | `04a`, `05a`, `06a`, `10a` | original total-effect pass; see Task E3 below |
| **E3** | **DONE** | `05a`, `10a` | Model-5-level H2 total effect + comparator; `table_s14a/b/c`; "main" relabel; comparison CSV |
| **F** | **DONE** | `05a`, `05b` | neutral state-owned vs independent floor figure, both variants |
| **G** | **DONE** | new `09_preperiod_diagnostics.Rmd` (was `10_`) | pre-period topic demeaning; pre-period-only z; topic-mapping diagnostic. Not registered in `master.Rmd` |
| **G2** | **DONE** | `09_preperiod_diagnostics.Rmd` (Section 4) | both pre-period variants re-run on the matched preferred models (Table 2 Model 6, Table 4 Model 5); side-by-side to text/CSV |
| **S15** | **DONE** | `09_preperiod_diagnostics.Rmd`, `10a` | four specs per matched model; `table_s15a`/`table_s15b` + side-by-side CSV |
| **C** | **DONE** | `04b`, `05b`, `06b` | direct series labels, new suffixed filenames only |

Serialization: F and C both touch `05b` — F first, C last. B / D / E fan out across
`04a` / `05a` / `06a` where independent.

### Task C — direct figure labels — DONE (kept)

This is the task that had failed repeatedly before, so the self-assessment is
recorded rather than just the outcome.

**What made it work.** The first attempt anchored each label just *outside* the end
of its fitted line and widened the x-axis to make room. That is the brittle approach:
the label is clipped whenever it is longer than the padding, and every fix for one
side breaks the other. Two rounds of this reproduced the historical failure exactly
— widening the right edge un-clipped "Russia-Aligned Post" and immediately clipped
"Russia-Aligned Pre" on the left.

The version kept anchors each label at the outer end of its own line but points the
text **inward** (`hjust = 0` for a left-hand series, `hjust = 1` for a right-hand
one), sitting just above the line via `vjust = -0.9`. Clipping is then impossible
regardless of label length, so the result does not depend on hand-tuned padding. The
shared helper `series_label_positions()` lives in `00_setup.R` beside the other
plotting helpers and computes the anchor from the same simple linear fit
`geom_smooth(method = "lm")` draws.

**Verification.**
- All three figures were produced by running the real chunks out of `04b`/`05b`/`06b`
  (via `knitr::purl`), not from a prototype, so what is on disk is what the scripts
  generate.
- Colour mappings were compared against the canonical figures and match exactly.
  This mattered: an early prototype of the 06b figure had a *different* mapping
  because it hand-rewrote the `align_indicator` construction; the real chunk
  reproduces the canonical assignment (Russia-Aligned Pre = blue, Neutral Pre =
  green, Russia-Aligned Post = dark red, Neutral Post = orange).
- All three canonical PNGs are unchanged. Worth noting: replaying the scripts to the
  labelled chunk *did* re-execute the original `ggsave()` calls and rewrite eight
  canonical PNGs with byte-different but visually identical output. Those were
  restored with `git checkout -- figures/`, and only the three `_labeled` files are
  new. Any future replay of these files needs the same cleanup.
- Both files purl cleanly, so no duplicate chunk labels were introduced.

**Assessment: keep.** The labelled versions are easier to read than the legend
versions — the eye stays on the discontinuity instead of moving to a key, and the
four-series plots in particular benefit. They are additions, not replacements: the
canonical figures still exist and nothing else references the new filenames.

## PHASE 3 — DEFERRED, not executed

Observations bearing on a future retirement of the `b`/`d` clones:

- The `05b` half of Task F and all of Task C are work a `b`-retirement would discard.
  Both were authorized with that known. Task C in particular adds three new figure
  chunks to `04b`/`05b`/`06b`; if those files are retired, the labelled figures
  either move to the `a` files or go with them.
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

Built as `scripts/09_preperiod_diagnostics.Rmd` (renumbered from `10_`), assembled by copying the estimation
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

### Task E3 — total-effect table corrections — DONE

Supersedes the original Task E table. Three changes: "headline" relabelled to
**"main"** throughout `table_s14` and `total_effect_comparison.csv`; the H2
comparison moved from Model-3 level to Model-5 level; and the H3a block
restructured so its sample asymmetry is visible.

> **Correction to the brief.** The brief described Table 2 Model 5 as "non-NATO
> sample, topic FE, all articles including military". It is **not** all articles:
> `data_non_nato` descends from `data_non_mil`, so Model 5 inherits Model 4's
> military exclusion and then drops the NATO countries. Table 2's own note is what
> misleads — "Model 4 omits military topics. Model 5 omits NATO allies" reads as
> though 5 only drops NATO. The brief also quoted Model 5's interaction as 0.2223;
> that is Model 6 (`matched_model_z`). Model 5 (`model2d_z`) is **0.2218979**, and
> the two differ only in the fourth decimal, consistent with "numerically
> unchanged". Reproduced at `|diff| = 0` before anything else was estimated.

H2 therefore has the same structural problem the brief already identified for H3a:
the main specification omits military coverage, and military is where the largest
post-invasion composition shift happens (Task G: its share of coverage rises 23% →
30%). A total effect estimated on a military-excluded sample would drop most of the
channel it exists to measure. On Donald's instruction H2 mirrors the H3a three-entry
structure, and `table_s14` is split into per-hypothesis panels.

**Results.** S14b and S14c run a complete 2x2 of sample (all topics vs military
omitted) against topic adjustment (FE vs none). S14a keeps two models, since H1's
main specification already uses all articles.

| Panel | Entry | Estimate | SE | Analytic p | Bootstrap p | N |
|---|---|---|---|---|---|---|
| **S14a — H1** | (1) total | **-0.2398** | 0.0346 | 3.93e-12 | — | 45,398 |
| | (2) main (T1 M5) | -0.2172 | 0.0362 | 1.96e-09 | — | 45,366 |
| **S14b — H2** | (1) non-NATO sample | 0.1656 | 0.0796 | 0.0437 | 0.1274 | 38,264 |
| | (2) total | 0.1745 | 0.0877 | 0.0531 | 0.1568 | 38,218 |
| | (3) main (T2 M5) | 0.2219 | 0.0691 | 0.00254 | **0.0344** | 31,405 |
| | (4) total, non-military | 0.2079 | 0.0712 | 0.00560 | **0.0382** | 31,251 |
| **S14c — H3a** | (1) non-NATO sample | -0.1926 | 0.1110 | 0.1083 | 0.2547 | 7,164 |
| | (2) total | -0.2218 | 0.1220 | 0.0939 | 0.2194 | 6,999 |
| | (3) main (T4 M4) | -0.3323 | 0.1108 | 0.0111 | **0.0530** | 6,094 |
| | (4) total, non-military | -0.3708 | 0.1166 | 0.00791 | **0.0446** | 6,028 |

**The 2x2 settles the attribution.** Holding the sample fixed, dropping the topic
adjustment moves almost nothing: H2 0.1656 → 0.1745 on all topics and 0.2219 →
0.2079 on the military-omitted sample; H3a -0.1926 → -0.2218 and -0.3323 →
-0.3708. Holding the adjustment fixed, excluding military moves a great deal:
H2 0.1656 → 0.2219 (with FE) and 0.1745 → 0.2079 (without); H3a -0.1926 → -0.3323
and -0.2218 → -0.3708. **The total-effect estimand is not what costs significance
— the military sample is.** Model 4 is significant in both panels (H2 bootstrap
p = 0.038, H3a p = 0.045), so on the main specification's own sample the total
effect survives.

**Reading — and this is the finding the three-entry structure exists to expose.**
H1 behaves as before: the total effect is *larger* than the main estimate and
strongly significant.

For H2 and H3a the picture is different, and it is **not** what a two-column
main-vs-total pair would have suggested. Read naively, H2 falls from 0.222 to
0.174 and loses significance, which looks like the topic fixed effects were doing
the work. The like-for-like comparator shows that is wrong: on the *same*
full-sample data, the topic-adjusted estimate is 0.166 and the total effect is
0.174 — dropping the topic FE moves the estimate by less than a tenth of a standard
error, and *upward*. What actually costs the significance is including military
coverage, which takes the estimate from 0.222 (non-military) to 0.166
(full sample). The same holds for H3a: main -0.332 → full-sample topic-adjusted
-0.193, while removing the topic FE from the full sample moves it only from -0.193
to -0.222.

So the honest statement is that **the H2 and H3a interactions are not robust to
including military coverage**, and that the topic adjustment itself is close to
irrelevant on a common sample. Neither total effect is significant on the
bootstrap p-values the paper reports (H2 0.157, H3a 0.219). Reported as found,
per instruction. The three-entry layout is what makes the sample effect separable
from the topic-FE effect; a two-column pair would have attributed the whole change
to the estimand.

**Implementation notes.**

- The H2 comparator and total effect are new models on `data_non_ukraine` filtered
  to non-NATO with all topics retained (`model2d_z_alltopic`, `model2d_z_total`).
  Their outcome is the full-window source z-score from `load-prob`; that is the
  right analogue of Model 5's outcome, because the non-military branch
  re-standardizes only on account of its sample change, and the all-topics sample
  is the original one.
- H3a needed no new estimation: all three entries already existed
  (`model5a_opt_z`, `model5a_opt_non_mil_z`, `model5a_opt_z_total`).
- `model2a_opt_z_total` (the old Model-3-level total) is removed from `05a` and
  from the serialized results, since nothing reads it any more.
- Both three-entry panels carry the note that the comparison is not
  apples-to-apples and why.

**Terminology.** The word "headline" no longer appears anywhere in the pipeline
scripts. It was ambiguous and, for H2 and H3a, wrong: it was applied to Table 2
Model 3 and Table 4 Model 3, which are the full-sample optimal-bandwidth columns,
not the paper's main results (Table 2 Model 5 and Table 4 Model 4).

- **S14 / S15 models** are labelled **main**, with derived columns to match
  (`main_estimate`, `main_se`, `main_p`, `main_boot_p`, `shift_in_main_ses`).
- **Sections 1-3 of `09_preperiod_diagnostics.Rmd`** are labelled **baseline**,
  and were **repointed to the paper's main unmatched specifications**:

  | Hypothesis | Object | Reported as | Raw-scale sibling |
  |---|---|---|---|
  | H1 | `model5_opt` | Table 1, Model 5 | `model2_opt` (Table 1, Model 2) |
  | H2 | `model2d_z` | Table 2, Model 5 | `model2d` (Table S3, Model 7) |
  | H3a | `model5a_opt_non_mil_z` | Table 4, Model 4 | `model5a_opt_non_mil` (Table S7, Model 4) |

  The H2 and H3a samples now omit military coverage, matching those columns. All
  three baselines are checked against their serialized objects at `|diff| = 0` in
  a new `diag-baseline-check` chunk before any diagnostic runs.

- **Task D's model labels** now name their table column:
  `H2_table2_model3`, `H2_table2_model6`, `H3a_table4_model3`, `H3a_table4_model5`.
  Regenerating that CSV changed labels only — its runner already seeded `dqrng`
  explicitly, so every bootstrap p-value is byte-identical.

**Coverage, after the repoint.** Sections 1-3 now diagnose the main *unmatched*
specifications and Section 4 the main *matched* ones, so between them the script
covers both versions of the results the paper leads with. The earlier gap is closed.

Under the repointed baselines both diagnostics leave the main results intact:

| Section | Spec | Baseline | Diagnostic | Baseline boot p | Diagnostic boot p |
|---|---|---|---|---|---|
| 1 (topic frozen) | H1 | -0.2172 | -0.2221 | — | — |
| | H2 | 0.2219 | 0.2406 | 0.0310 | 0.0280 |
| | H3a | -0.3323 | -0.3725 | 0.0510 | 0.0340 |
| 2 (pre-period z) | H1 | -0.2172 | -0.2418 | — | — |
| | H2 | 0.2219 | 0.2705 | 0.0310 | 0.0078 |
| | H3a | -0.3323 | -0.2948 | 0.0510 | 0.0598 |

Section 1 moves every estimate by well under half a baseline SE and, on the new
baselines, every H2/H3a bootstrap p *falls*. Section 2 strengthens H1 and H2; for
H3a it shrinks the estimate by 11% and pushes the bootstrap p from 0.051 to 0.060,
the one place either normalization makes a result weaker. H3a's baseline is
marginal to begin with (Table 4 Model 4 bootstrap p = 0.051).

### Task G2 — pre-period variants on the matched preferred models — DONE

Task G ran the variants against the *unmatched* headline specs. This section repeats
both against the preferred matched columns — **Table 2 Model 6** (`matched_model_z`,
05a) and **Table 4 Model 5** (`matched_model`, 06a) — as Section 4 of
`09_preperiod_diagnostics.Rmd`.

**Matched headlines reproduced exactly before anything else was estimated**, as
required: `0.2222964347` and `-0.3803738052`, `|diff| = 0` against the serialized
objects. Matching is `method = "exact"` and therefore deterministic; the matched
rows are built once and then held fixed, so neither variant re-runs matching.

| Spec | Variant | Estimate | SE | Analytic p | Bootstrap p |
|---|---|---|---|---|---|
| H2 matched | headline | 0.2223 | 0.0690 | 0.00247 | 0.0334 |
| H2 matched | (i) pre-period topic demeaned | 0.2368 | 0.0688 | 0.00132 | 0.0232 |
| H2 matched | (ii) pre-period z-score | 0.2650 | 0.0644 | 0.000176 | 0.0084 |
| H3a matched | headline | -0.3804 | 0.1120 | 0.00530 | 0.0262 |
| H3a matched | (i) pre-period topic demeaned | -0.3821 | 0.1118 | 0.00510 | 0.0242 |
| H3a matched | (ii) pre-period z-score | -0.3521 | 0.0860 | 0.00148 | 0.0100 |

N is 31,379 (43 source clusters) for every H2 row and 5,721 (13 clusters) for every
H3a row — **no source was dropped** by the pre-period z-scoring in either matched
sample, unlike the unmatched case where three were.

**Reading.** Both variants leave the matched results intact, and if anything
strengthen them: every variant is significant on the bootstrap p-value the paper
reports, and both bootstrap p-values fall relative to their headline. Variant (i)
moves H2 by 0.21 headline SEs and H3a by 0.015 — essentially nothing. That H3a is
almost perfectly insensitive here is expected rather than surprising: exact matching
on topic and publication day already balances the topic composition across the
comparison groups, which is the channel variant (i) probes, so there is little left
for a frozen topic adjustment to change.

**Two implementation notes.**

1. `06a` selects only
   `sentiment_z, running, running_probabilistic, treatment, csto, topic_clean,
   source_domain, country` into its matching frame, dropping `sentiment_clean`,
   which variant (ii) needs in order to rebuild the z-score from pre-invasion
   moments. `sentiment_clean` is carried through here. Matching is on
   `csto ~ running + topic_clean` only, so a passenger column cannot change which
   rows match — and the `|diff| = 0` check above proves it did not.
2. Both files match on `running` (the day-scale variable), not
   `running_probabilistic`. Preserved as-is.

> **Repo-wide finding, surfaced not fixed.** `dqrng::dqset.seed()` is called
> **nowhere** in this repository, and `fwildclusterboot` >= 0.13 draws its bootstrap
> weights through `dqrng`'s own RNG stream. `set.seed(3184)` alone therefore does
> **not** make `boottest()` reproducible: re-running Task G's own script shifted its
> bootstrap p-values by a few thousandths (e.g. H2 section-2 headline 0.2517 ->
> 0.2613) while every estimate, SE, analytic p, N and bandwidth stayed byte
> identical. That is Monte Carlo error at B = 4999, well within the noise band and
> changing no conclusion, but it means **every wild-bootstrap p-value in the paper is
> reproducible only up to Monte Carlo error**, including the starred ones in Tables
> 2 and 4.
>
> **Resolved.** Donald authorised the repo-wide fix; `dqrng::dqset.seed(3184)` now
> sits beside `set.seed(3184)` in `00_setup.R`, and the local line has been removed
> from the diagnostics script so setup is the single source of truth. See
> "RNG fix" below.

### Table S15 — pre-period adjustment variants on the matched models — DONE

Four specifications per matched preferred model, built by extending the Task G2
machinery in Section 4 of `09_preperiod_diagnostics.Rmd`:

1. main specification as published;
2. pre-period topic adjustment only (topic FE removed, outcome demeaned by its
   pre-invasion topic means);
3. pre-period z-scoring only (outcome standardized on pre-invasion source
   means/SDs, topic FE retained);
4. both (pre-period source z-score, then demeaned by pre-invasion topic means
   computed **on that same pre-z scale**, no topic FE).

Identical matched rows, bandwidth machinery and source clustering across all four;
WCR bootstrap at `B = 4999` under the now-fixed seed. **Both matched headlines
reproduced at `|diff| = 0`** before any variant was estimated
(`0.2222964347`, `-0.3803738052`).

| Model | Spec | Estimate | SE | Analytic p | Bootstrap p |
|---|---|---|---|---|---|
| H2 matched (T2 M6) | (1) main | 0.2223 | 0.0690 | 0.00247 | 0.0334 |
| | (2) pre-period topic | 0.2368 | 0.0688 | 0.00132 | 0.0232 |
| | (3) pre-period z | 0.2650 | 0.0644 | 0.000176 | 0.0084 |
| | (4) both | **0.2809** | 0.0644 | 0.0000828 | **0.0046** |
| H3a matched (T4 M5) | (1) main | -0.3804 | 0.1120 | 0.00530 | 0.0290 |
| | (2) pre-period topic | -0.3821 | 0.1118 | 0.00510 | 0.0242 |
| | (3) pre-period z | -0.3521 | 0.0860 | 0.00148 | 0.0110 |
| | (4) both | -0.3527 | 0.0839 | 0.00123 | **0.0054** |

N is 31,379 / 43 clusters for every H2 row and 5,721 / 13 for every H3a row; no
source is dropped by the pre-period z-scoring in either matched sample.

**Reading.** Freezing either adjustment at pre-invasion values — or both at once —
leaves both results intact and, if anything, sharpens them. Every bootstrap
p-value falls relative to its headline, and spec 4 is the strongest column in both
panels. The two adjustments contribute in different ways across the two models:
for H2 the source z-scoring does most of the work (0.2223 → 0.2650) while the topic
adjustment adds a little (→ 0.2809); for H3a the topic adjustment does essentially
nothing (-0.3804 → -0.3821, a shift of 0.015 headline SEs) and the z-scoring
*shrinks* the estimate slightly while tightening the standard error enough that
significance improves. H3a's insensitivity to the topic channel is expected: exact
matching on topic and publication day already balances topic composition across
the comparison groups.

**Presentation.** Two 4-column panels rather than one 8-column table, since the two
models carry different interaction terms: `table_s15a` (state ownership) and
`table_s15b` (Russia-aligned). Stars are driven by the bootstrap p-values through
`override_interaction_stars()`, as in Tables 2 and 4. Both panels carry a footnote
recording that their bootstrap p-values are computed under the fixed seed and may
differ in the third decimal place from Tables 2 and 4 until those are re-rendered.

## Second renumber — diagnostics promoted into the pipeline

`09_preperiod_diagnostics.Rmd` is no longer a side script: its Section 4 produces the
models behind appendix table S15, so it is now a registered pipeline step.

| Was | Now |
|---|---|
| `10_preperiod_diagnostics.Rmd` | `09_preperiod_diagnostics.Rmd` |
| `09a_publication_outputs_prob.Rmd` | `10a_publication_outputs_prob.Rmd` |
| `09b_publication_outputs_days.Rmd` | `10b_publication_outputs_days.Rmd` |
| `09d_publication_outputs_drop.Rmd` | `10d_publication_outputs_drop.Rmd` |

Run order in `master.Rmd` is now 04–07 (three variants each) → 08 bandwidth →
**09 pre-period diagnostics** → 10{a,b,d} publication outputs. The dependency runs
the right way: 09 reads `05/06_*_prob.rds` for its `|diff| = 0` headline checks and
writes `09_preperiod_results_prob.rds`, which 10a reads for table S15.

Both READMEs updated (structure tree, pipeline tables, file-description tables, ASCII
diagram, the "each of 04–07 and 10 has three variants" sentence, and the pre-trend
output table). YAML titles updated in all four renamed files. Repo-wide sweep for the
old names outside `scripts/archive/` returns nothing.

The script's own framing was corrected too: it previously declared itself "AUTHOR
DIAGNOSTICS ONLY. Not paper outputs; not registered in master.Rmd", both clauses of
which are now false. The Overview and the summary-file header now state that
Sections 1–3 remain author diagnostics while Section 4 produces paper output.

## RNG fix — bootstrap reproducibility (repo-wide)

`dqrng::dqset.seed(3184)` is now set in `00_setup.R` immediately after
`set.seed(3184)`, with a comment explaining why both streams need seeding.
`fwildclusterboot` >= 0.13 draws its bootstrap weights through `dqrng`, so base R's
seed alone never controlled `boottest()`. `B = 4999` is unchanged.

Verified: the same model bootstrapped in two independent R sessions now returns
byte-identical results (`boot_p = 0.0306061212`, `boot_se = 0.1119295183` both
times). Before the fix the same comparison drifted by a few thousandths.

> ### ⚠ All previously generated wild-bootstrap p-values are SUPERSEDED
>
> Every bootstrap p-value produced before this commit was drawn from an unseeded
> `dqrng` stream and is reproducible only up to Monte Carlo error (roughly ±0.006
> at p ≈ 0.25 with B = 4999). Point estimates, standard errors, analytic p-values,
> sample sizes and bandwidths are **unaffected** — only the bootstrap columns move,
> and no conclusion in the paper changes. But for final numbers, every script that
> produces a bootstrap p-value needs re-rendering under the fixed seed:
>
> | Script | What it re-generates |
> |---|---|
> | `04a_main_rdd_analysis_prob.Rmd` | `04_h1_results_prob.rds` (no WCR, but re-run for a clean chain) |
> | `05a_diff_in_disc_analysis_prob.Rmd` | `bootstrap_se` for all H2 models, incl. `matched_model_z` |
> | `06a_russian_alignment_analysis_prob.Rmd` | `bootstrap_se` for all H3a models, incl. `matched_model` |
> | `07a_ethnic_russian_analysis_prob.Rmd` | `bootstrap_se` for the H3b models |
> | `04b/05b/06b/07b`, `04d/05d/06d/07d` | the day and drop variants' bootstraps |
> | `08_bandwidth_sensitivity.Rmd` | bandwidth-sensitivity intervals |
> | `09_preperiod_diagnostics.Rmd` | Sections 1–4, incl. the `table_s15` models |
> | `10{a,b,d}_publication_outputs_*.Rmd` | every table whose stars come from a WCR p |
>
> Until 05a and 06a are re-rendered, the bootstrap p-values in Tables 2, 4 and S14
> remain the old unseeded ones, while `table_s15` (built after the fix) carries
> seeded values. `table_s15` footnotes this explicitly. The affected numbers differ
> only in the third decimal place.

## Phase 3 — typology robustness (in progress)

### Reconcile 10b/10d — DONE

The three publication scripts had diverged: 10b/10d still carried the
Russian-related columns 10a had commented out (Table 2 Model 6 `model3a_z`,
Table 4 Model 5 `model5a_opt_russian_z`). Both now match 10a — Table 2 is six
models, Table 4 is five. Tables 1, 3 and 5 were already identical. Column
headers, coefficient labels and note text aligned at the same time; titles left
variant-specific. The orphaned models stay in 05b/05d and 06b/06d until the
slimming pass.

### `11_typology_robustness.Rmd` — DONE

One table per hypothesis, typologies as columns, replacing the practice of
reproducing the whole appendix three times. Registered in `master.Rmd` after the
10s. Reads the twelve serialized result objects; writes `table_s16{a,b,c,d}` and
`typology_robustness_comparison.csv` to `figures/tables/prob/`, alongside the
other appendix tables.

Specifications compared, per Donald: H1 Table 1 Model 5; H2 Table 2 Models 5 and
6; H3a Table 4 Models 4 and 5; H3b Table 5 Models 4 and 5. H1 has no matched
sibling, so it shows one specification.

**Results** (estimate, bootstrap p where one exists):

| Hypothesis | Spec | Probabilistic | Day | Drop |
|---|---|---|---|---|
| H1 | Main | -0.217 | -0.267 | *missing* |
| H2 | Main | 0.222 (.034) | 0.248 (.009) | **0.154 (.097)** |
| H2 | Matched | 0.222 (.033) | 0.182 (.012) | **0.088 (.260)** |
| H3a | Main | -0.332 (.053) | -0.265 (.101) | -0.364 (.046) |
| H3a | Matched | -0.380 (.029) | -0.311 (.060) | -0.364 (.044) |
| H3b | Main | -0.002 (.989) | 0.032 (.831) | *missing* |
| H3b | Matched | 0.015 (.917) | 0.049 (.721) | *missing* |

**Reading.** H3b is a stable null across typologies, as expected. H3a is stable
in magnitude (spread 0.6-0.9 probabilistic SEs) though its bootstrap p wanders
either side of 0.05 — the same knife-edge the B increase was meant to settle, so
this is worth re-reading after the re-render. **H2 is the sensitive one**: under
the drop typology the matched estimate falls from 0.222 to 0.088 and is nowhere
near significant (p = 0.26), a spread of 1.9 probabilistic SEs. That is the one
result in the paper that visibly depends on how missing publication times were
handled, and it is exactly what this table exists to surface.

> **Stale `.rds` found.** Three cells are empty because `04_h1_results_drop.rds`
> and `07_ethnic_results_drop.rds` were serialized on 2026-03-04, before the
> current `04d` and `07d` scripts. Both scripts *do* define and serialize the
> missing objects (`model5_opt`; `model6a_opt_non_mil_z`, `matched_model_z`), so
> re-rendering those two fills the gaps. The script reports missing cells
> explicitly rather than silently omitting them.

### Still to do — handed off

Slimming `04{b,d}`, `05{b,d}`, `06{b,d}`, `07{b,d}`. Specified in
`plans/claude_code_brief_phase3_variant_slimming.md`, written for a fresh session
because the work spans ~10,000 lines across eight files.

**Decision taken:** the b/d scripts keep the objects behind Tables 1-5 per
variant, not just the seven `11` consumes, so `10b`/`10d` remain rebuildable.
Keep lists, drop lists and verification steps are in the brief. All figure code
stays in both `b` and `d`, including unused figures, so the two variants stay
consistent and nothing has to be recreated later.

Also noted for that pass: the `## Total Effect, Sentiment-Z (No FEs)` section
exists in **all three** 06 files, is serialized nowhere and consumed by nothing.
In `06a` it appears to duplicate the Task E `model5a_opt_z_total` specification
exactly; the two should be merged rather than both kept. Within the section,
`model5_full_csto_z` uses `sentiment_z` while `model5_total_neutral` uses
`sentiment_clean`, despite the heading.

## Bootstrap replications raised to B = 99,999

`run_wild_bootstrap()` and `compare_cluster_levels()` now default to `B = 99999`,
the explicit `B = 4999` overrides in the LOO loops of `05{a,b,d}` and `06{a,b,d}`
were raised to match, `BOOT_B` in `09` follows, and `SE_NOTE_BOOT` now reads
`B=99999`. One B throughout, so one number in the footnote.

**Why.** The Monte Carlo SE of a bootstrap p-value is `sqrt(p(1-p)/B)` — about
0.003 at p = 0.05 with B = 4999. Table 4 Model 4 sits at p ≈ 0.0484, only 0.0016
below the threshold, so its significance star was decided by the draw:

| B | MC SE | Distance to 0.05 | Chance of landing below |
|---|---|---|---|
| 4,999 | 0.0030 | 0.53 SE | ~70% |
| 9,999 | 0.0021 | 0.75 SE | ~77% |
| 99,999 | 0.00068 | 2.37 SE | ~99% |

Measured across five seeds at B = 4,999 that model returned 0.0466, 0.0498,
0.0502, 0.0510, 0.0514 — straddling 0.05. At B = 99,999, three seeds gave
0.04823, 0.04841, 0.04852. B = 9,999 was rejected because it still gets the star
wrong about one run in four, and costs the same as 4,999 (both are
overhead-dominated).

**Cost.** Measured per call: 0.06–0.08 s at B = 4,999, 0.67–0.82 s at B = 99,999,
for both the 13-cluster and 43-cluster cases. The pipeline makes ~295 calls, so
the increase is **≈ 3.7 minutes across all three variants** — an over-estimate,
since many calls are on smaller by-topic subsets.

**Unaffected entirely** (zero bootstrap calls, verified by parsing every script):
`04{a,b,d}`, `08_bandwidth_sensitivity`, and `10{a,b,d}`, which read stored
bootstrap results rather than computing them. The long runtimes in `04` and in the
`b`/`d` variants come from model fitting, `rdbwselect`, the LOO loops and
`MatchIt` — none of which scale with B.

> ### ⚠ Do not rebuild tables before re-rendering their sources
>
> `SE_NOTE_BOOT` now says `B=99999`, but every bootstrap value currently in the
> `.rds` files was computed at `B = 4999` under an unseeded `dqrng`. Rebuilding
> `10a` right now would produce tables whose footnote claims 99,999 while the
> numbers behind the stars are 4,999. The producing scripts must be re-rendered
> first — see the queue below, which the dqrng fix already required.

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

**Task C**

- `figures/rdd/days/invasion_on_sentiment_non_mil_labeled.png`
- `figures/diff_in_disc/days/invasion_discs_non_mil_labeled.png`
- `figures/heterogeneity/days/state_align_discs_labeled.png`

The three canonical PNGs are byte-for-byte unchanged.

**Task F**

- `figures/diff_in_disc/prob/neutral_floor_side_by_side.png`
- `figures/diff_in_disc/days/neutral_floor_side_by_side.png` (identical content)

**Task E**

- `figures/tables/prob/table_s14_total_effect.tex` — appendix table, headline and
  total columns paired for H1, H2, H3a
- `figures/tables/prob/table_s14_total_effect.html`
- `figures/tables/prob/total_effect_comparison.csv` — estimates, SEs, N, bandwidth

**Task E3** (appendix, supersedes the original Task E table)

- `figures/tables/prob/table_s14a_total_effect_h1.{tex,html}`
- `figures/tables/prob/table_s14b_total_effect_h2.{tex,html}`
- `figures/tables/prob/table_s14c_total_effect_h3a.{tex,html}`
- `figures/tables/prob/total_effect_comparison.csv` — refreshed, `kind` uses "main"
- `figures/tables/prob/table_s14_total_effect.*` **deleted** — the single wide
  table is no longer produced by any chunk

**Table S15** (appendix)

- `figures/tables/prob/table_s15a_preperiod_matched_h2.{tex,html}`
- `figures/tables/prob/table_s15b_preperiod_matched_h3a.{tex,html}`
- `figures/tables/prob/table_s15_preperiod_matched.csv` — full side-by-side
- `data/intermediate/09_preperiod_results_prob.rds` — the eight fitted models and
  their bootstraps, read by `10a`

**Task G2** (author diagnostics, not paper outputs)

- `output/diagnostics/preperiod_matched_comparison.csv` — six rows: matched
  headline plus both variants, for H2 and H3a
- `output/diagnostics/preperiod_matched_shifts.csv` — shift of each variant against
  its own matched headline
- `output/diagnostics/preperiod_matched_dropped_sources.csv` — empty; no source was
  dropped from either matched sample
- Section 4 block appended to `output/diagnostics/preperiod_diagnostics_summary.txt`

**Task G** (author diagnostics, not paper outputs)

- `output/diagnostics/preperiod_topic_demeaned_comparison.csv`
- `output/diagnostics/preperiod_zscore_comparison.csv`
- `output/diagnostics/preperiod_zscore_dropped_sources.csv`
- `output/diagnostics/topic_mapping_diagnostic.csv`
- `output/diagnostics/preperiod_diagnostics_summary.txt`
- `output/09_preperiod_diagnostics.html` (rendered report; gitignored)

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
