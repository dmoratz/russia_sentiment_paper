# Plan: Update 07 Ethnic Russian Analysis Files

## Instructions for Claude Code

### Resumability

1. Create `07_ethnic_update_progress.md` in the project root. Initialize with every task below as `- [ ]`.
2. Before each task, read `07_ethnic_update_progress.md`. Skip any `- [x]` task.
3. After completing each task, mark it `- [x]` and save immediately.
4. If resuming after compaction/restart, read `07_ethnic_update_progress.md` and jump to the first unchecked task.
5. If a model or variable is not found, insert a `# TODO` comment and mark the task `- [~]`.

## Overview

The 07 files need to be substantially simplified. H3b is an alternative specification for H3 that shows the null (ethnic Russian population doesn't explain the pattern). Table 6 needs only 5 Z-score models. Most existing FE-based models, by-topic breakdowns, saturated models, and LOO analysis should be removed.

**Use `06C_russian_alignment_analysis_prob.Rmd` as the primary reference for code patterns.** The 07 file should mirror how 06C handles Z-scores, bandwidth selection, matching, and bootstrap — substituting `high_russia` for `csto` throughout.

## Reference Files

- `06C_russian_alignment_analysis_prob.Rmd` — code pattern reference (how Z-score, matching, rdrobust, etc. are implemented)
- `07C_ethnic_russian_analysis_prob.Rmd` — the file to modify

Do 07C first. Then duplicate to 07, 07B, 07D.

## What Table 6 Needs

5 models, all using Z-score DV:

| Col | Model name | Type | Description |
|-----|-----------|------|-------------|
| (1) | `model6a_high_z` | rdrobust | Separate RDD, high ethnic Russian pop, Z-score, non-mil |
| (2) | `model6a_low_z` | rdrobust | Separate RDD, low ethnic Russian pop, Z-score, non-mil |
| (3) | `model6a_opt_z` | feols | Interaction, optimal BW, Z-score, topic FEs |
| (4) | `model6a_opt_non_mil_z` | feols | Non-mil, re-optimized BW, Z-score, topic FEs |
| (5) | `matched_model_z` | feols | Matched, Z-score, topic FEs |

Models 3-5 need bootstrap SEs for `treatment:high_russia`.

---

## Critical Implementation Details (from 06C)

### Z-Score Computation

Compute on the full `data_ethnic_state` dataset ONCE, then subsets inherit it:

```r
data_ethnic_state <- data_ethnic_state %>%
  group_by(source_domain) %>%
  mutate(sentiment_z = (sentiment_clean - mean(sentiment_clean, na.rm = TRUE)) / 
                   sd(sentiment_clean, na.rm = TRUE)) %>%
  ungroup()
```

### Separate RDDs (rdrobust)

Following 06C's pattern for CSTO/neutral separate RDDs (lines 140-217):

1. Filter to the subgroup (e.g., `high_russia == 1`) AND non-military topics
2. Divide `running_probabilistic` by 86400 to convert to days (this is already done for `data_ethnic_state` in 07C)
3. Compute Z-score within the subgroup
4. Create covariates matrix: `covs_matrix <- model.matrix(~ topic_clean - 1, data = subset_data)`
5. Run `rdrobust(y = sentiment_z, x = running_variable, covs = covs_matrix, cluster = source_domain)`

### Bandwidth Selection for Z-Score Models

06C residualizes before bandwidth selection:

```r
resid_y <- feols(sentiment_z ~ 1 | topic_clean + high_russia, 
                 data = data_ethnic_state)$residuals

bw <- rdbwselect(y = resid_y,
                 x = data_ethnic_state$running_probabilistic,
                 kernel = "triangular",
                 cluster = data_ethnic_state$source_domain,
                 p = 1,
                 bwselect = "mserd")
```

Note: For the non-mil subset, residualize on that subset:

```r
resid_y <- feols(sentiment_z ~ 1 | topic_clean + high_russia, 
                 data = data_ethnic_state_non_mil)$residuals
```

### Matching

Follow 06C lines 854-908 exactly, substituting `high_russia` for `csto`:

```r
matching_data <- optimal_bandwidth_data_non_mil_z %>%
  select(sentiment_z, running, running_probabilistic, treatment, high_russia, 
         topic_clean, source_domain, country)

ps_model <- matchit(
  high_russia ~ running + topic_clean,
  data = matching_data,
  method = "exact",
  ratio = 1
)

matched_data <- match.data(ps_model)

matched_model_z <- feols(
  sentiment_z ~ running_probabilistic * treatment * high_russia | topic_clean,
  cluster = ~source_domain,
  data = matched_data
)

boot_matched_model_z <- run_wild_bootstrap(matched_model_z, "treatment:high_russia")
```

**IMPORTANT:** The matching uses `running` (the day variable), NOT `running_probabilistic`. This is because exact matching on continuous time would match nothing — matching on day is the right granularity. Verify that the `running` column exists in the data.

### Bootstrap

Use `run_wild_bootstrap` from `00_setup.R` as-is. Do NOT define a local version. Whatever settings are in `00_setup.R` (Rademacher, Webb, etc.) will be used consistently across all scripts.

---

## Phase 1: Keep and Modify

### Task 1.1: Keep file header, setup, load data

Keep the YAML, setup chunk, and load chunk. Update the Overview text to reflect the simplified analysis.

### Task 1.2: Keep ethnic subset creation

Keep the `ethnic-data` chunk that creates `data_ethnic` and `data_ethnic_state`. This is the base data needed for everything.

### Task 1.3: Add Z-score computation to data_ethnic_state

After the existing `data_ethnic_state` creation (which already filters to `state_owned == 1` and converts running variable to days), add:

```r
data_ethnic_state <- data_ethnic_state %>%
  group_by(source_domain) %>%
  mutate(sentiment_z = (sentiment_clean - mean(sentiment_clean, na.rm = TRUE)) / 
                   sd(sentiment_clean, na.rm = TRUE)) %>%
  ungroup()
```

### Task 1.4: Keep visualization

Keep the `ethnic-plot` chunk (or update it to use `sentiment_z` if desired).

---

## Phase 2: Separate RDD Models (NEW)

### Task 2.1: High ethnic Russian population RDD (Z-score)

```r
data_high <- data_ethnic_state %>% 
  filter(high_russia == 1) %>%
  filter(!topic_clean %in% "Military")

# Recompute Z-score within this subset (following 06C pattern for separate RDDs)
data_high <- data_high %>%
  group_by(source_domain) %>%
  mutate(sentiment_z = (sentiment_clean - mean(sentiment_clean, na.rm = TRUE)) / 
                   sd(sentiment_clean, na.rm = TRUE)) %>%
  ungroup()

covs_matrix <- model.matrix(~ topic_clean - 1, data = data_high)

model6a_high_z <- rdrobust(
  y = data_high$sentiment_z,
  x = data_high$running_probabilistic,
  covs = covs_matrix,
  cluster = data_high$source_domain
)

summary(model6a_high_z)
```

### Task 2.2: Low ethnic Russian population RDD (Z-score)

Same pattern but `filter(high_russia == 0)`.

---

## Phase 3: Interaction Model — Optimal BW, Z-Score (NEW)

### Task 3.1: Bandwidth selection and model estimation

```r
# Residualize for bandwidth selection
resid_y <- feols(sentiment_z ~ 1 | topic_clean + high_russia, 
                 data = data_ethnic_state)$residuals

bw_ethnic_z <- rdbwselect(y = resid_y,
                          x = data_ethnic_state$running_probabilistic,
                          kernel = "triangular",
                          cluster = data_ethnic_state$source_domain,
                          p = 1,
                          bwselect = "mserd")

optimal_bw_ethnic_z <- bw_ethnic_z$bws[1, 1]
cat("Optimal bandwidth (Z-score):", round(optimal_bw_ethnic_z, 1), "days\n")

optimal_bandwidth_data_z <- data_ethnic_state %>%
  filter(running_probabilistic < optimal_bw_ethnic_z,
         running_probabilistic > -optimal_bw_ethnic_z)

model6a_opt_z <- feols(
  sentiment_z ~ running_probabilistic * treatment * high_russia | topic_clean,
  cluster = ~source_domain,
  data = optimal_bandwidth_data_z
)

summary(model6a_opt_z)

boot_model6a_opt_z <- run_wild_bootstrap(model6a_opt_z, "treatment:high_russia")
cat("Bootstrap SE:", boot_model6a_opt_z$se, "\n")
cat("Bootstrap p-value:", boot_model6a_opt_z$p_val, "\n")
```

---

## Phase 4: Non-Military Topics, Z-Score (NEW)

### Task 4.1: Non-mil model

```r
data_ethnic_state_non_mil <- data_ethnic_state %>%
  filter(!topic_clean %in% "Military")

# Recompute Z-score on non-mil subset
data_ethnic_state_non_mil <- data_ethnic_state_non_mil %>%
  group_by(source_domain) %>%
  mutate(sentiment_z = (sentiment_clean - mean(sentiment_clean, na.rm = TRUE)) / 
                   sd(sentiment_clean, na.rm = TRUE)) %>%
  ungroup()

# Residualize for bandwidth selection
resid_y <- feols(sentiment_z ~ 1 | topic_clean + high_russia, 
                 data = data_ethnic_state_non_mil)$residuals

bw_ethnic_non_mil_z <- rdbwselect(y = resid_y,
                                  x = data_ethnic_state_non_mil$running_probabilistic,
                                  kernel = "triangular",
                                  cluster = data_ethnic_state_non_mil$source_domain,
                                  p = 1,
                                  bwselect = "mserd")

optimal_bw_ethnic_non_mil_z <- bw_ethnic_non_mil_z$bws[1, 1]

optimal_bandwidth_data_non_mil_z <- data_ethnic_state_non_mil %>%
  filter(running_probabilistic < optimal_bw_ethnic_non_mil_z,
         running_probabilistic > -optimal_bw_ethnic_non_mil_z)

model6a_opt_non_mil_z <- feols(
  sentiment_z ~ running_probabilistic * treatment * high_russia | topic_clean,
  cluster = ~source_domain,
  data = optimal_bandwidth_data_non_mil_z
)

summary(model6a_opt_non_mil_z)

boot_model6a_opt_non_mil_z <- run_wild_bootstrap(model6a_opt_non_mil_z, "treatment:high_russia")
cat("Bootstrap SE:", boot_model6a_opt_non_mil_z$se, "\n")
cat("Bootstrap p-value:", boot_model6a_opt_non_mil_z$p_val, "\n")
```

---

## Phase 5: Matched Model, Z-Score (NEW)

### Task 5.1: Matching and model estimation

Follow 06C lines 854-908. Use the non-mil optimal BW data from Phase 4.

```r
library(MatchIt)
library(cobalt)

matching_data <- optimal_bandwidth_data_non_mil_z %>%
  select(sentiment_z, running, running_probabilistic, treatment, high_russia, 
         topic_clean, source_domain, country)

ps_model <- matchit(
  high_russia ~ running + topic_clean,
  data = matching_data,
  method = "exact",
  ratio = 1
)

summary(ps_model)

# Balance check
bal.tab(ps_model, un = TRUE, stats = c("m", "v"), thresholds = c(m = 0.1))

matched_data <- match.data(ps_model)
cat("Matched observations:", nrow(matched_data), "\n")

matched_model_z <- feols(
  sentiment_z ~ running_probabilistic * treatment * high_russia | topic_clean,
  cluster = ~source_domain,
  data = matched_data
)

summary(matched_model_z)

boot_matched_model_z <- run_wild_bootstrap(matched_model_z, "treatment:high_russia")
cat("Bootstrap SE:", boot_matched_model_z$se, "\n")
cat("Bootstrap p-value:", boot_matched_model_z$p_val, "\n")
```

**NOTE:** Verify the `running` column exists in the data. If the day running variable has a different name in the 07 files, adjust accordingly.

---

## Phase 6: Keep Placebo Test

### Task 6.1: Keep existing placebo

Keep the `placebo-dec-ethnic` chunk. It works and contributes to S10. The only change: if the placebo currently uses `sentiment_clean`, consider switching to `sentiment_z` for consistency (check what 06C's placebo uses — it uses `sentiment_z`). Update accordingly.

---

## Phase 7: Remove Everything Else

### Task 7.1: Remove these sections

Delete all of the following (these are chunks/sections in 07C):

- `model6a` (basic, no FEs) — chunk `ethnic-reg`
- `model6a_full` (full data, topic FEs) — chunk `ethnic-full`
- `model6a_opt` (FE version) — the model inside chunk `ethnic-optimal` (keep bandwidth computation only if different from Phase 3's)
- `model6a_opt_non_mil` (FE version) — chunk `ethnic-non-mil`
- `model6a_opt_russian` — chunk `ethnic-russian`
- `model6a_fully_saturated` + manual bootstrap — chunks `ethnic-fully-saturated` and `ethnic-fully-saturated-bootstrap`
- All by-topic models (full data + opt BW) — chunks `ethnic-topic-full` and `ethnic-topic-opt`
- LOO analysis — chunk `loo-country-ethnic`
- All summary tables (Table 4I, 4J, 4K) — chunks `table4i`, `table4j`, `table4k`

---

## Phase 8: Update Saved Results

### Task 8.1: Rewrite save chunk

```r
results_ethnic_prob <- list(
  # Z-score models for Table 6
  model6a_high_z = model6a_high_z,
  model6a_low_z = model6a_low_z,
  model6a_opt_z = model6a_opt_z,
  model6a_opt_non_mil_z = model6a_opt_non_mil_z,
  matched_model_z = matched_model_z,

  # Bootstrap SEs (only for feols interaction models)
  bootstrap_se = list(
    model6a_opt_z = boot_model6a_opt_z,
    model6a_opt_non_mil_z = boot_model6a_opt_non_mil_z,
    matched_model_z = boot_matched_model_z
  ),

  # Placebo
  model_placebo_ethnic = model_placebo_ethnic,
  optimal_bw_placebo_ethnic = optimal_bw_placebo_ethnic,
  bootstrap_se_placebo = list(
    model_placebo_ethnic = boot_model_placebo_ethnic
  ),

  # Bandwidths
  optimal_bw_ethnic_z = optimal_bw_ethnic_z,
  optimal_bw_ethnic_non_mil_z = optimal_bw_ethnic_non_mil_z
)

saveRDS(results_ethnic_prob, file.path(DATA_INTERMEDIATE, "07_ethnic_results_prob.rds"))
```

---

## Applying to Other 07 Variants

After 07C is validated:

**For each variant**, check the existing file to identify:
1. The running variable name (`running_probabilistic` in 07C, likely `running` in 07, `running_continuous` in 07B, etc.)
2. The date variable for placebo (`date_publish_probabilistic` in 07C)
3. The .rds output filename
4. Any data loading differences (07D filters out no-time articles)

### 07 (days)
- Running variable: likely `running` (in days already — may not need /86400 conversion)
- Output: `07_ethnic_results.rds`

### 07B (continuous)
- Running variable: likely `running_continuous` (in seconds — needs /86400 for rdrobust)
- Output: `07_ethnic_results_continuous.rds`

### 07D (drop)
- Running variable: check file
- Data may filter out articles without publication times
- Output: `07_ethnic_results_drop.rds`

## Model Assignment

Use **Opus** for 07C (primary, involves creating new model patterns). 

**STOP after 07C is complete.** Inform the user:

> "07C is complete. Please review the output, then switch to Sonnet and re-run to continue with 07, 07B, and 07D."

Do NOT proceed to the other variants in the same session. The user will switch to Sonnet and restart.

Use **Sonnet** for 07, 07B, 07D (mechanical adaptation).

## Additional Cleanup

**Remove the local `run_wild_bootstrap` definition** in 07C (lines 53-69). This file currently defines its own version with `type = "rademacher"`. Delete it so the file uses the correct Webb/fnw11 version from `00_setup.R`.
