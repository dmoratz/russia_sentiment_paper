# Plan: Centralize Packages and Helpers in 00_setup.R

## Context

Currently, several analysis scripts (05/06 family) duplicate:
1. `p_load()` calls for packages `fwildclusterboot`, `MatchIt`, `cobalt`, `rbounds`,
   `sensemakr`, `ggridges` that should live centrally in `00_setup.R`
2. Redundant `library(fwildclusterboot)` and `library(ggridges)` calls
3. An identical `run_wild_bootstrap()` helper function defined in 7 different files

The 04 family and 05A are already clean (no extra library calls or function defs).

---

## Changes Required

### File: `scripts/00_setup.R`
1. Add 6 packages to the central `p_load()` call:
   `fwildclusterboot, MatchIt, cobalt, rbounds, sensemakr, ggridges`
2. Add `run_wild_bootstrap()` function definition (identical across all files):
   ```r
   run_wild_bootstrap <- function(model, param, clustid = "source_domain", B = 4999) {
     boot_result <- boottest(
       object = model,
       param = param,
       clustid = clustid,
       B = B,
       impose_null = TRUE,
       bootstrap_type = "fnw11",
       type = "webb"
     )
     list(
       se = boot_result$point_estimate / boot_result$t_stat,
       p_val = boot_result$p_val,
       ci_lower = boot_result$conf_int[1],
       ci_upper = boot_result$conf_int[2],
       t_stat = boot_result$teststat
     )
   }
   ```

### Files to Clean (remove duplicated content)

| File | Remove p_load | Remove library() | Remove run_wild_bootstrap |
|------|---------------|-----------------|--------------------------|
| `05_diff_in_disc_analysis.Rmd` | `p_load(fwildclusterboot)` | `library(fwildclusterboot)` | ✓ |
| `05B_diff_in_disc_analysis_drop.Rmd` | `p_load(fwildclusterboot)` | `library(fwildclusterboot)` | ✓ |
| `05C_diff_in_disc_analysis_prob.Rmd` | `p_load(fwildclusterboot, MatchIt, cobalt, rbounds, sensemakr)` | `library(fwildclusterboot)` | ✓ |
| `06_russian_alignment_analysis.Rmd` | `p_load(fwildclusterboot, MatchIt, cobalt, rbounds, sensemakr)` | `library(fwildclusterboot)` + mid-file `library(ggridges)` | ✓ |
| `06A_russian_alignment_analysis_continuous.Rmd` | same | same | ✓ |
| `06B_russian_alignment_analysis_drop.Rmd` | same | same | ✓ |
| `06C_russian_alignment_analysis_prob.Rmd` | `p_load(fwildclusterboot, MatchIt, cobalt, rbounds, sensemakr, ggridges)` | none separate | ✓ |

**Leave as-is:**
- `options(digits = 10)` in 06 family — analysis-specific precision override, not a library call
- `set.seed(3184)` in 05 files — harmless repetition, not a library call
- All 04 family files — already clean
- `05A_diff_in_disc_analysis_continuous.Rmd` — already clean

---

## Sub-Agent Deployment

All edits are independent and run in parallel (8 agents total):

| Agent | File | Task |
|-------|------|------|
| 1 | `scripts/00_setup.R` | Add 6 packages + `run_wild_bootstrap` |
| 2 | `scripts/05_diff_in_disc_analysis.Rmd` | Remove 3 items |
| 3 | `scripts/05B_diff_in_disc_analysis_drop.Rmd` | Remove 3 items |
| 4 | `scripts/05C_diff_in_disc_analysis_prob.Rmd` | Remove 3 items |
| 5 | `scripts/06_russian_alignment_analysis.Rmd` | Remove 4 items |
| 6 | `scripts/06A_russian_alignment_analysis_continuous.Rmd` | Remove 4 items |
| 7 | `scripts/06B_russian_alignment_analysis_drop.Rmd` | Remove 4 items |
| 8 | `scripts/06C_russian_alignment_analysis_prob.Rmd` | Remove 2 items |

---

## Execution Tracking

| Step | File | Status |
|------|------|--------|
| 1 | `00_setup.R` | ✅ Done |
| 2 | `05_diff_in_disc_analysis.Rmd` | ✅ Done |
| 3 | `05B_diff_in_disc_analysis_drop.Rmd` | ✅ Done |
| 4 | `05C_diff_in_disc_analysis_prob.Rmd` | ✅ Done |
| 5 | `06_russian_alignment_analysis.Rmd` | ✅ Done |
| 6 | `06A_russian_alignment_analysis_continuous.Rmd` | ✅ Done |
| 7 | `06B_russian_alignment_analysis_drop.Rmd` | ✅ Done |
| 8 | `06C_russian_alignment_analysis_prob.Rmd` | ✅ Done |

---

## Verification

After all edits:
1. Grep for `library(`, `p_load(`, and `run_wild_bootstrap <-` across the 7 cleaned files —
   should return zero matches.
2. Confirm `00_setup.R` contains all 6 new packages and the `run_wild_bootstrap` definition.
3. Spot-check that `run_wild_bootstrap()` calls in the analysis files still resolve (function
   now comes from `00_setup.R` via `source("00_setup.R")`).
