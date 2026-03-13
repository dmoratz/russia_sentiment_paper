# Plan: Propagate 06C Changes + Update 05C + Update 08

## Context

The user has made changes to `06C_russian_alignment_analysis_prob.Rmd` — both
cosmetic formatting cleanup and substantive analysis changes (z-score as primary
outcome throughout, LOO robustness using `sentiment_z`, etc.). These changes need
to propagate to the other three 06 variants. Separately, `05C` needs two changes:
drop country fixed effects everywhere, and add z-score models as a parallel
analysis. Both sets of changes then propagate across their respective families, and
file 08 gets new z-score table sections.

---

## Files to Modify (in order)

| Step | File | Change |
|------|------|--------|
| 1 | `scripts/06_russian_alignment_analysis.Rmd` | Full propagation from 06C |
| 2 | `scripts/06A_russian_alignment_analysis_continuous.Rmd` | Full propagation from 06C |
| 3 | `scripts/06B_russian_alignment_analysis_drop.Rmd` | Full propagation from 06C |
| 4 | `scripts/05C_diff_in_disc_analysis_prob.Rmd` | Drop country FEs + add z-score parallel |
| 5 | `scripts/05_diff_in_disc_analysis.Rmd` | Propagate 05C changes |
| 6 | `scripts/05A_diff_in_disc_analysis_continuous.Rmd` | Propagate 05C changes |
| 7 | `scripts/05B_diff_in_disc_analysis_drop.Rmd` | Propagate 05C changes |
| 8 | `scripts/08_publication_outputs.Rmd` | Add z-score table sections |

---

## Step 1–3: Propagate 06C → 06, 06A, 06B

**Approach:** Use 06C as the complete structural template. Each file gets an
exact mirror of 06C with only the substitutions below. The existing country-dummy
logic in 06A/06B (using `country_multi`, `country_dummy`, `i(country_dummy, ...)`)
is replaced by 06C's simpler FE approach (`| topic_clean + source_domain`).

### Per-file substitutions

| Element | 06 (days) | 06A (continuous) | 06B (drop) |
|---------|-----------|------------------|------------|
| Running variable | `running` | `running_continuous` | `running_continuous` |
| Day scaling | None (already days) | `/86400` suffix where needed | `/86400` suffix where needed |
| Extra data filter | None | None | `filter(has_time == TRUE)` after load |
| Figure path | `FIGURES_HETEROGENEITY_DAYS` | `FIGURES_HETEROGENEITY_CONT` | `FIGURES_HETEROGENEITY_DROP` |
| Chunk name suffix | (none / base) | `-cont` | `-drop` |
| Table number | Table 3 | Table 3A | Table 3F |
| RDS output filename | `06_alignment_results.rds` | `06_alignment_results_continuous.rds` | `06_alignment_results_drop.rds` |
| Save-list object name | `results_het` | `results_het_cont` | `results_het_drop` |
| Title suffixes | "(Days)" | "(Continuous)" | "(Drop No-Time)" |

### Structural changes from 06C (applied to all three)

1. **Setup chunk**: Add `options(digits = 10)`; move `run_wild_bootstrap` helper
   into setup chunk (it currently lives in the load chunk in 06); add
   `p_load(fwildclusterboot, MatchIt, cobalt, rbounds, sensemakr)`.

2. **Z-score creation**: After factor conversion, add:
   ```r
   data_align_state <- data_align_state %>%
     group_by(source_domain) %>%
     mutate(sentiment_z = (sentiment_clean - mean(sentiment_clean, na.rm = TRUE)) /
                          sd(sentiment_clean, na.rm = TRUE)) %>%
     ungroup()
   ```
   (repeated for each data subset: `data_align_state_csto`, `data_align_state_neutral`,
   `data_align_state_non_mil`, `data_align_state_russian`.)

3. **Primary models**: Use `sentiment_z` as outcome in all main `feols`/`rdrobust`
   models (replacing `sentiment_clean`). The z-score RDD models
   (`model5a_csto_z`, `model5a_neutral_z`) use `rdrobust(y = ...$sentiment_z, ...)`.

4. **Bandwidth selection**: Use residualization of `sentiment_z` (not `sentiment_clean`)
   for `rdbwselect`:
   ```r
   resid_y <- feols(sentiment_z ~ 1 | topic_clean + csto, data = ...)$residuals
   bw_align <- rdbwselect(y = resid_y, ...)
   ```

5. **LOO analysis**: Update LOO loop to use `sentiment_z` as outcome (replacing
   `sentiment_clean` currently in 06's LOO).

6. **Matching**: Use `sentiment_z` in matched model and `lm_model` for sensemakr.

7. **Save list**: Must include all z-score model objects to match 06C structure:
   `model5a_z`, `model5a_csto_z`, `model5a_neutral_z`, `model5a_opt_z`,
   `model5a_opt_non_mil_z`, `model5a_opt_russian_z`, and corresponding bootstrap
   results. The full list of saved objects mirrors 06C's `results_het_prob` save.

8. **"Full FE" models** (06A/06B-specific clean-up): Replace the `country_dummy`
   / `i(country_dummy, ref = "single_source")` pattern with 06C's fixed-effect
   approach: `| topic_clean + source_domain` (no country — mirroring 06C exactly).

---

## Step 4: Update 05C

### A. Drop Country Fixed Effects Everywhere

Find every `feols` call that contains `| country + topic_clean` and change to
`| topic_clean`. Find any `| country` (standalone) and remove the country term.
Also apply to: `model2a_full_*` topic models (currently `| country`), placebo
model `model4a`, matched model, DID model.

Affected models (approximately):
- `model2a`, `model2a_opt`, `model2b`, `model2d`, `model3a`, `model3a_opt`
- `model3a_opt_saturated` (its complex FE spec may also reference country — review)
- `model4a` (placebo)
- `model_did`
- All five `model2a_full_*` topic models (currently `| country`)
- All five `model2a_opt_*` topic models (currently `| country`)
- `matched_model`

Also: the separate RDD models (`model2_state_rdd`, `model2_ind_rdd`) use
`covs = model.matrix(~ country + source_domain + topic_clean - 1, ...)` — remove
`country` from that covariate matrix.

### B. Add Z-Score Parallel Analysis

After data loading and factor conversion, add `sentiment_z` computation:
```r
data_non_ukraine <- data_non_ukraine %>%
  group_by(source_domain) %>%
  mutate(sentiment_z = (sentiment_clean - mean(sentiment_clean, na.rm = TRUE)) /
                       sd(sentiment_clean, na.rm = TRUE)) %>%
  ungroup()
```
(Apply to each subset used: `data_non_mil`, `optimal_bandwidth_data`, etc.)

Add z-score parallel models alongside (not replacing) existing ones:
- `model2a_z` — same spec as `model2a` but `sentiment_z ~ ...`
- `model2a_opt_z` — optimal BW version with z-score
- `model2b_z` — non-military with z-score
- `model2d_z` — non-NATO with z-score
- `model3a_z` — Russian-related with z-score
- `model3a_opt_z` — Russian-related + optimal BW with z-score

Add corresponding bootstrap calls for each z-score model.

Add all z-score models and bootstrap results to the `results_h2_prob` save list.

---

## Steps 5–7: Propagate 05C → 05, 05A, 05B

Same changes as Step 4 (country FE drop + z-score parallel analysis), with:

| File | Running variable | Extra filter |
|------|-----------------|--------------|
| `05_diff_in_disc_analysis.Rmd` | `running` | None |
| `05A_diff_in_disc_analysis_continuous.Rmd` | `running_continuous` | None |
| `05B_diff_in_disc_analysis_drop.Rmd` | `running_continuous` | `filter(has_time == TRUE)` at load |

Chunk names, table numbers, and RDS filenames adjust accordingly (Table 2, 2A,
2F; `05_h2_results.rds`, `_continuous.rds`, `_drop.rds`).

---

## Step 8: Update File 08

### A. Add z-score table sections for H2 (05 family)

After each existing Table 2x section, add a corresponding z-score variant using
the new `model2a_z`, `model2a_opt_z`, etc. from each result set. Suggested naming:

- Table 2-Z: H2 Z-Score (Days) — from `results_h2`
- Table 2A-Z: H2 Z-Score (Continuous) — from `results_h2_cont`
- Table 2F-Z: H2 Z-Score (Drop) — from `results_h2_drop`
- Table 2I-Z: H2 Z-Score (Probabilistic) — from `results_h2_prob`

Each table displays `model2a_z`, `model2a_opt_z`, `model2b_z`, `model2d_z`,
`model3a_z`, `model3a_opt_z` with the same `coef_map`, `gof_omit`, and `stars`
settings as the corresponding raw-sentiment table.

### B. Add z-score table sections for alignment (06 family)

Check whether 08 already has sections referencing `results_align$model5a_z` etc.
If not, add:

- Table 3-Z: Alignment Z-Score (Days) — from `results_align$model5a_z`, etc.
- Table 3A-Z: Alignment Z-Score (Continuous) — from `results_align_cont`
- Table 3F-Z: Alignment Z-Score (Drop) — from `results_align_drop`
- Table 3I-Z: Alignment Z-Score (Probabilistic) — from `results_align_prob`

### C. Update inputs list in 08 header

Verify the `**Inputs:**` section still lists all correct RDS file names (no
filenames change so this should be a no-op).

---

## Critical Cross-File Consistency Checks

After editing, verify that each save-list in 05/06 files contains all model names
that file 08 references by `$model_name`. Key checks:

- `results_align` (from 06) must contain: `model5a_csto`, `model5a_neutral`,
  `model5a_full`, `model5a_opt`, `model5a_opt_non_mil`, `model5a_opt_russian`,
  `model5a_opt_full_fe`, `model5a_opt_non_mil_full_fe`, `model5a_fully_saturated`,
  `matched_model`, `bootstrap_se$*`, plus new z-score models.
- Same naming check for `results_align_cont`, `results_align_drop`, `results_align_prob`.
- `results_h2_prob` must contain all models currently referenced in 08's Table 2I,
  plus new z-score models `model2a_z`, etc.

---

## Sub-Agent Deployment

Each step is implemented by deploying parallel sub-agents — one per file. Steps
that touch multiple files deploy multiple sub-agents simultaneously.

| Step | Files | Sub-agents deployed |
|------|-------|---------------------|
| 1 | `06_russian_alignment_analysis.Rmd` | 1 |
| 2 | `06A_russian_alignment_analysis_continuous.Rmd` | 1 |
| 3 | `06B_russian_alignment_analysis_drop.Rmd` | 1 |
| 4 | `05C_diff_in_disc_analysis_prob.Rmd` | 1 |
| 5–7 | `05_diff_in_disc_analysis.Rmd`, `05A_...`, `05B_...` | 3 (parallel) |
| 8 | `08_publication_outputs.Rmd` | 1 |

Steps 1–3 can run in parallel (all three 06 variants are independent).
Step 4 also runs in parallel with 1–3.
Steps 5–7 can run in parallel (after step 4 is complete).
Step 8 runs last (depends on all prior steps).

---

## Execution Tracking

Update this table as steps are completed.

| Step | File | Status |
|------|------|--------|
| 1 | `06_russian_alignment_analysis.Rmd` | ✅ Done |
| 2 | `06A_russian_alignment_analysis_continuous.Rmd` | ✅ Done |
| 3 | `06B_russian_alignment_analysis_drop.Rmd` | ✅ Done |
| 4 | `05C_diff_in_disc_analysis_prob.Rmd` | ✅ Done |
| 5 | `05_diff_in_disc_analysis.Rmd` | ✅ Done |
| 6 | `05A_diff_in_disc_analysis_continuous.Rmd` | ✅ Done |
| 7 | `05B_diff_in_disc_analysis_drop.Rmd` | ✅ Done |
| 9 | `04A_rdd_analysis_continuous.Rmd` | ✅ Done |
| 10 | `04B_rdd_analysis_drop.Rmd` | ✅ Done |
| 11 | `04C_rdd_analysis_prob.Rmd` | ✅ Done |
| 12 | `08_publication_outputs.Rmd` | ✅ Done |

---

## Verification

After all edits:
1. **Linting**: Read through each modified file to check R syntax.
2. **Name-match audit**: grep for `results_align$model5a` in 08 and confirm every
   referenced name exists in 06's save list. Same for 05 family.
3. **Run order**: 06 → 06A → 06B → 05C → 05 → 05A → 05B → 08. Each script
   should knit cleanly, regenerating the corresponding RDS.
4. **08 outputs**: After all upstream scripts have run, knit 08 to confirm all
   tables render without errors.
