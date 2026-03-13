# Plan: Upgrade 05C to Match 06C Structure + Propagate to 05/05A/05B/08

## Context

`05C_diff_in_disc_analysis_prob.Rmd` and `06C_russian_alignment_analysis_prob.Rmd`
run structurally parallel analyses (diff-in-discontinuity design, same dataset, same
running variable) but ask different questions:

| Dimension | 05C | 06C |
|-----------|-----|-----|
| Treatment indicator | `state_owned` (state vs independent media) | `csto` (CSTO member vs neutral country) |
| Key coefficient | `treatment:state_owned` | `treatment:csto` |
| Sample | all non-Ukraine, non-NATO | non-NATO only (CSTO + neutral) |
| Primary outcome | `sentiment_clean` (z-score parallel) | `sentiment_z` (primary) |
| Unique feature | DID robustness check | — |

Both files should share the same robustness architecture. After a thorough comparison,
05C is missing several models, has some organizational issues, and uses B=999 in the
LOO bootstrap instead of B=4999.

**Scope of this plan:**
1. Add missing models to 05C and reorganize sections
2. Propagate all changes to 05, 05A, 05B (parallel with different running variables)
3. Update 08 to include the new models in its tables

---

## Confirmed User Decisions

All questions have been answered — no outstanding items:

| # | Question | Decision |
|---|----------|----------|
| A6 | Country-level facet visualization | ❌ Skip |
| C | Placebo filter to non-military | ✅ Yes — add non-military filter |
| D | Add `matched_model_z` | ✅ Yes |
| 4 | Add `model3a_opt_full_fe` | ✅ Yes |
| 5 | Add z-score by-topic models | ✅ Yes |
| 6 | Table 2I layout | ✅ 8-column main + supplemental |

---

## Part 1: Changes to 05C

### A. Missing Models (to Add)

#### A1. Full-FE parallel for main model — `model2a_full`
06C has `model5a_full`: same as main model but with `| topic_clean + source_domain`.
05C's `model2a` only uses `| topic_clean`. **Add:**
```r
model2a_full <- feols(sentiment_clean ~ running_probabilistic * treatment * state_owned |
                      topic_clean + source_domain,
                      cluster = ~source_domain, data = data_non_ukraine)
boot_model2a_full <- run_wild_bootstrap(model2a_full, "treatment:state_owned")
```
Place immediately after `model2a` / `boot_model2a`.

#### A2. Full-FE parallel for optimal bandwidth — `model2a_opt_full_fe`
06C has `model5a_opt_full_fe`. **Add:**
```r
model2a_opt_full_fe <- feols(sentiment_clean ~ running_probabilistic * treatment * state_owned |
                              topic_clean + source_domain,
                              cluster = ~source_domain, data = optimal_bandwidth_data)
boot_model2a_opt_full_fe <- run_wild_bootstrap(model2a_opt_full_fe, "treatment:state_owned")
```
Place immediately after `model2a_opt` block.

#### A3. Full-FE parallel for non-military — `model2b_full_fe`
06C has `model5a_opt_non_mil_full_fe`. **Add:**
```r
model2b_full_fe <- feols(sentiment_clean ~ running_probabilistic * treatment * state_owned |
                          topic_clean + source_domain,
                          cluster = ~source_domain, data = data_non_mil)
boot_model2b_full_fe <- run_wild_bootstrap(model2b_full_fe, "treatment:state_owned")
```
Place immediately after the `model2b` block.

#### A4. Full-FE parallel for Russian-related — `model3a_opt_full_fe`
06C has `model5a_opt_rus_full_fe`. **Add:**
```r
model3a_opt_full_fe <- feols(sentiment_clean ~ running_probabilistic * treatment * state_owned |
                              topic_clean + source_domain,
                              cluster = ~source_domain, data = data_russian_combined_bw)
boot_model3a_opt_full_fe <- run_wild_bootstrap(model3a_opt_full_fe, "treatment:state_owned")
```
Place immediately after `model3a_opt` / `model3a_opt_saturated` block.

#### A5. Z-score RDD models for state and independent media
06C has `model5a_csto_z` and `model5a_neutral_z` — z-score rdrobust models for the
two sub-populations. 05C's `model2_state_rdd` and `model2_ind_rdd` are raw sentiment
only. **Add z-score versions:**
```r
model2_state_rdd_z <- rdrobust(
  y = data_state_only$sentiment_z,
  x = data_state_only$running_probabilistic,
  covs = model.matrix(~ source_domain + topic_clean - 1, data = data_state_only),
  cluster = data_state_only$source_domain, kernel = "triangular", p = 1
)
model2_ind_rdd_z <- rdrobust(
  y = data_ind_only$sentiment_z,
  x = data_ind_only$running_probabilistic,
  covs = model.matrix(~ source_domain + topic_clean - 1, data = data_ind_only),
  cluster = data_ind_only$source_domain, kernel = "triangular", p = 1
)
```
Place immediately after `model2_state_rdd` / `model2_ind_rdd`.

#### A6. Z-Score By-Topic Models
Add z-score versions of each by-topic model, mirroring 06C's structure. For each
topic variant (`pol`, `mil`, `econ`, `cult`, `oth`), add a `_z` version using
`sentiment_z` as outcome. Example:
```r
model2a_full_pol_z <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned |
                             topic_clean + source_domain,
                             cluster = ~source_domain,
                             data = filter(data_non_ukraine, topic_clean == "pol"))
```
Place each z-score topic model immediately after its raw counterpart. Applies to
both full-data and optimal-bandwidth by-topic variants.

#### A7. LOO Matching Analysis
06C has a full leave-one-out loop that reruns matching for each dropped country and
stores `matched_loo_results` + `matched_loo_summary`. 05C only has the unmatched LOO.
**Add a matched LOO section** mirroring 06C's structure, placed at the end of the
Robustness section (after Sensitivity Analysis — see Section E). The loop should:
- For each country, drop it, recompute bandwidth, run `matchit(state_owned ~ running + topic_clean, method = "exact")`, extract matched data, fit feols, bootstrap
- Store in `matched_loo_results` list; summarize in `matched_loo_summary` tibble

### B. Bootstrap Fix

**LOO bootstrap uses B=999; should be B=4999** to match all other bootstrap calls.
Fix in the LOO loop:
```r
# Change:
boot_result <- run_wild_bootstrap(model, "treatment:state_owned", B = 999)
# To:
boot_result <- run_wild_bootstrap(model, "treatment:state_owned", B = 4999)
```

### C. Placebo Filter (Confirmed)

Add non-military filter to 05C's placebo test (`model4a`), matching 06C's
`model_placebo_nonmil`. The placebo section should filter pre-invasion articles
to non-military topics before running the rdrobust/feols placebo model.

### D. Matched Model Z-Score (Confirmed)

Add `matched_model_z` alongside `matched_model` in 05C, using `sentiment_z` as
the outcome in the matched-data feols. Add corresponding bootstrap call. Place
immediately after `matched_model` / `boot_matched_model`.

### E. Section Reorganization

05C's current structure groups robustness checks haphazardly. Reorganize to mirror
06C's clean hierarchy:

**Current 05C structure (problem areas):**
- Z-score models are bunched in a single chunk far from their raw-model counterparts
- DID robustness check is buried in an `# Additional Analysis` section at the end
- `# Robustness Checks` is a flat catch-all (non-mil, non-NATO, z-scores, Russian, combined)
- LOO appears before Placebo; Matching after Placebo — inconsistent ordering

**Proposed new 05C structure:**
```
# Overview
# Load Data
# Separate RDDs by Media Type
  ## State-Owned Media Only (RDD)
  ## Independent Media Only (RDD)
# Diff-in-Disc Analysis
  ## Full Data
    ### Full Data, Topic FEs (model2a + bootstrap + z-score)
    ### Full Data, Topic + Source FEs (model2a_full + bootstrap)
    ### Effect Size
  ## Optimal Bandwidth
    ### Bandwidth Selection
    ### Optimal BW, Topic FEs (model2a_opt + bootstrap + z-score)
    ### Optimal BW, Full FEs (model2a_opt_full_fe + bootstrap)
    ### DID Within Bandwidth (model_did) ← move from Additional Analysis
  ## Non-Military Topics
    ### Non-Military, Topic FEs (model2b + bootstrap + z-score)
    ### Non-Military, Full FEs (model2b_full_fe + bootstrap)
    ### Visualization (Non-Military)
  ## Non-NATO Countries (model2d + bootstrap + z-score)
  ## Russian-Related Articles
    ### Russian-Related (model3a + bootstrap + z-score)
    ### Russian-Related + Combined Filter (model3a_opt + bootstrap + z-score)
    ### Russian-Related Full FEs (model3a_opt_full_fe + bootstrap)
    ### Saturated Model
# By-Topic Analysis
  ## Full Data By Topic (raw + z-score)
  ## Per-Topic Optimal Bandwidth (raw + z-score)
# Robustness
  ## Leave-One-Out Country Robustness
  ## Placebo Test (December 7th, non-military)
  ## Matching
  ## Sensitivity Analysis (OVB)
  ## Leave-One-Out Matching Robustness  ← new, placed last
# Summary Tables
  ## Table 2I: Main Results (8 columns)
  ## Table 2I: Supplemental (full-FE non-mil + Russian)
  ## Table 2I: By Topic (Optimal BW)
  ## Table 2I: By Topic (Full Data)
# Save Results
# Session Info
```

**Key reorganization moves:**
1. Z-score models move adjacent to their raw-model counterparts (no separate chunk)
2. DID check moves to `## Optimal Bandwidth` subsection (not `# Additional Analysis`)
3. Placebo moves directly after LOO Country (before Matching)
4. LOO Matching added at the very end of Robustness (after Sensitivity Analysis)
5. Sensitivity analysis stays immediately after Matching

### F. Summary Table Update

**Main Table 2I** (8 columns — confirmed):

| Col | Model | Description |
|-----|-------|-------------|
| (1) | `model2a` | Full data, topic FEs |
| (2) | `model2a_full` | Full data, topic + source FEs ← **NEW** |
| (3) | `model2a_opt` | Optimal BW, topic FEs |
| (4) | `model2a_opt_full_fe` | Optimal BW, full FEs ← **NEW** |
| (5) | `model2b` | Non-military, topic FEs |
| (6) | `model2d` | Non-NATO, topic FEs |
| (7) | `model3a_opt` | Russian-related + combined BW |
| (8) | `model3a_opt_saturated` | Saturated (source×topic, topic×treatment) |

**Supplemental Table 2I-S** (2 columns — new, for full-FE robustness checks):

| Col | Model | Description |
|-----|-------|-------------|
| (1) | `model2b_full_fe` | Non-military, topic + source FEs |
| (2) | `model3a_opt_full_fe` | Russian-related + combined BW, full FEs |

### G. Save List Updates

Add to `results_h2_prob`:
- `model2a_full`, `boot$model2a_full`
- `model2a_opt_full_fe`, `boot$model2a_opt_full_fe`
- `model2b_full_fe`, `boot$model2b_full_fe`
- `model3a_opt_full_fe`, `boot$model3a_opt_full_fe`
- `model2_state_rdd_z`, `model2_ind_rdd_z`
- `matched_loo_results`, `matched_loo_summary`
- `matched_model_z`, `boot$matched_model_z`
- All z-score by-topic model objects

---

## Part 2: Propagate to 05, 05A, 05B

Same structural changes as Part 1, with running-variable substitutions:

| Element | 05 (days) | 05A (continuous) | 05B (drop) |
|---------|-----------|------------------|------------|
| Running variable | `running` | `running_continuous` | `running_continuous` |
| Extra filter | None | None | `filter(has_time == TRUE)` |
| Placebo date variable | `date_publish` | `date_publish_continuous` | `date_publish_continuous` |
| Figure path | `FIGURES_DIFF_DISC_DAYS` | `FIGURES_DIFF_DISC_CONT` | `FIGURES_DIFF_DISC_DROP` |
| Chunk suffixes | (none) | `-cont` | `-drop` |
| Table numbers | Table 2 | Table 2A | Table 2F |
| RDS filename | `05_h2_results.rds` | `05_h2_results_continuous.rds` | `05_h2_results_drop.rds` |
| Save-list name | `results_h2` | `results_h2_cont` | `results_h2_drop` |

**Deployment:** After 05C is approved and finalized, 05/05A/05B get sub-agents that
use the updated 05C as their structural template with the substitutions above.

---

## Part 3: Update File 08

### New model references to add:

**H2 main tables — expand from 6 to 8 columns (Tables 2, 2A, 2F, 2I):**
- Add `model2a_full` (col 2) and `model2a_opt_full_fe` (col 4) to each table
- Column order: model2a, model2a_full, model2a_opt, model2a_opt_full_fe, model2b, model2d, model3a_opt, model3a_opt_saturated

**H2 supplemental tables — add new (Tables 2-S, 2A-S, 2F-S, 2I-S):**
- Two-column tables: model2b_full_fe, model3a_opt_full_fe

**H2 z-score tables — existing 2-Z/2A-Z/2F-Z/2I-Z already cover model2a_z etc.;**
no new z-score table needed for the full-FE variants (low priority).

**H1 (04 family) — no changes needed**
**Alignment (06 family) — no changes needed**

---

## Sub-Agent Deployment Plan

Steps are sequential (05C must be finalized before 05/05A/05B, which must be
finalized before 08).

| Phase | Steps | Agents | Notes |
|-------|-------|--------|-------|
| Phase 1 | Update 05C | 1 agent | Core work; uses 06C as structural reference |
| Phase 2 | Propagate to 05, 05A, 05B | 3 parallel agents | Use updated 05C as template |
| Phase 3 | Update file 08 | 1 agent | After Phase 2 complete |

**Total agents:** 5 (sequential phases, parallel within Phase 2)

---

## Execution Tracking

| Step | File | Status |
|------|------|--------|
| 1 | `05C_diff_in_disc_analysis_prob.Rmd` | ✅ Done |
| 2 | `05_diff_in_disc_analysis.Rmd` | ✅ Done |
| 3 | `05A_diff_in_disc_analysis_continuous.Rmd` | ✅ Done |
| 4 | `05B_diff_in_disc_analysis_drop.Rmd` | ✅ Done |
| 5 | `08_publication_outputs.Rmd` | ✅ Done |

---

## Verification

After all edits:
1. Grep for new model names (`model2a_full`, `model2a_opt_full_fe`, `model2b_full_fe`,
   `model3a_opt_full_fe`, `model2_state_rdd_z`, `model2_ind_rdd_z`, `matched_model_z`)
   in each updated 05 file — all present.
2. Verify save lists in 05/05A/05B/05C contain all new model objects.
3. Verify 08 references to new model names resolve against save list names.
4. Check LOO bootstrap B value = 4999 (not 999) across all 05 files.
5. Structural audit: confirm z-score models are adjacent to raw counterparts,
   not in a separate block.
6. Confirm placebo sections in all 05 files filter to non-military topics.
7. Confirm LOO Matching section appears last in Robustness (after Sensitivity).
