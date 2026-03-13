# Plan: Update 05C_diff_in_disc_analysis_prob.Rmd

This document describes the changes needed to bring 05C into methodological alignment with the handcrafted 06C file. The reference file is `06C_russian_alignment_analysis_prob.Rmd`. The target file is `05C_diff_in_disc_analysis_prob.Rmd`.

The core modeling question differs between the two files (05C: `state_owned` interaction; 06C: `csto` interaction), so model names, interaction terms, and variable names should NOT be changed. Only the methodological patterns described below need to be updated.

**Note:** Two changes have already been made by hand and should NOT be re-applied:
1. The placebo test's `difftime` result has already been converted to days (the `/ 86400` is already in the placebo `mutate`).
2. The `running` column creation (`floor(running_probabilistic / 86400)`) in the matching sections has already been removed — the `running` column already exists in the data.

---

## 1. Convert `running_probabilistic` to days

### Problem

In 06C, the running variable is converted from seconds to days (`/ 86400`) before any models are fit. In 05C, the running variable stays in raw seconds throughout. This affects coefficient interpretation, bandwidth magnitudes, and rdrobust results.

### What to do

Add a conversion step in the `load-prob` chunk (around line 42–59), after the factor conversions and z-score computation are done. Add this to both `data_non_ukraine` and `data`:

```r
# Convert running variable from seconds to days
data_non_ukraine <- data_non_ukraine %>%
  mutate(running_probabilistic = running_probabilistic / 86400)

data <- data %>%
  mutate(running_probabilistic = running_probabilistic / 86400)
```

### Downstream label updates

- All bandwidth output `cat()` statements currently say `"seconds"` — update these to say `"days"` wherever they appear (lines ~245, 470, 598, 605, 612, 619, 626, 769).
- The axis label on all plots currently says `"Hours Pre/Post Invasion"` — update to `"Days Pre/Post Invasion"` (lines ~219, 374, 811).
- The placebo plot axis label says `"Seconds Pre/Post Announcement"` — update to `"Days Pre/Post Announcement"` (line ~813).

### Already done (do NOT re-apply)

- The placebo `difftime` already includes `/ 86400`.
- The matching `running` column derivation has already been removed (it already exists in the data).

---

## 2. Residualize outcome before bandwidth selection

### Problem

In 06C, before calling `rdbwselect`, the outcome is residualized against fixed effects (e.g., `feols(sentiment_clean ~ 1 | topic_clean + source_domain + state_owned)`). This prevents FE-absorbed variation from inflating the bandwidth estimate. In 05C, raw `sentiment_clean` is passed directly to `rdbwselect` everywhere.

### What to do

Apply the residualization pattern at each `rdbwselect` call. The appropriate FEs to residualize against depend on what's in the corresponding `feols` model. Use `sentiment_clean` residuals for `sentiment_clean` models.

**Important note on FE choice:** Do NOT include `source_domain` in the residualization for the z-score models. The z-score models in 06C residualize against `topic_clean + csto` (the group variable), not `source_domain`. The analogous pattern for 05C is `topic_clean + state_owned`.

Here is every `rdbwselect` call in 05C and what to change:

#### a) Main optimal bandwidth (chunk `optimal-bw-prob`, line ~235)

Currently:
```r
bw_select <- rdbwselect(y = data_non_ukraine$sentiment_clean,
                        x = data_non_ukraine$running_probabilistic, ...)
```

Change to:
```r
resid_y <- feols(sentiment_clean ~ 1 | topic_clean + source_domain + state_owned,
                 data = data_non_ukraine)$residuals

bw_select <- rdbwselect(y = resid_y,
                        x = data_non_ukraine$running_probabilistic, ...)
```

#### b) Combined filter bandwidth (chunk `combined-robust-prob`, line ~457)

Currently:
```r
bw_select_combined <- rdbwselect(y = data_combined_filtered$sentiment_clean,
                                  x = data_combined_filtered$running_probabilistic, ...)
```

Change to:
```r
resid_y <- feols(sentiment_clean ~ 1 | topic_clean + source_domain + state_owned,
                 data = data_combined_filtered)$residuals

bw_select_combined <- rdbwselect(y = resid_y,
                                  x = data_combined_filtered$running_probabilistic, ...)
```

#### c) Per-topic optimal bandwidths (chunk `topic-opt-bw-prob`, lines ~595–627)

These subsets have only one topic level, so residualize against `state_owned` only (no `topic_clean`, no `source_domain`):

For each topic (Political, Military, Economic, Culture, Other), change the pattern from:
```r
bw_pol <- rdbwselect(y = data_pol$sentiment_clean, x = data_pol$running_probabilistic, ...)
```

To:
```r
resid_y_pol <- feols(sentiment_clean ~ 1 | state_owned,
                     data = data_pol)$residuals
bw_pol <- rdbwselect(y = resid_y_pol, x = data_pol$running_probabilistic, ...)
```

Apply the same pattern for `bw_mil`, `bw_econ`, `bw_cult`, `bw_oth`.

#### d) LOO bandwidth (chunk `loo-country-prob`, line ~703)

Currently:
```r
bw_loo <- rdbwselect(y = data_loo$sentiment_clean,
                     x = data_loo$running_probabilistic, ...)
```

Change to:
```r
resid_y_loo <- feols(sentiment_clean ~ 1 | topic_clean + state_owned,
                     data = data_loo)$residuals
bw_loo <- rdbwselect(y = resid_y_loo,
                     x = data_loo$running_probabilistic, ...)
```

(Use `topic_clean + state_owned` here rather than `+ source_domain` because dropping a country may cause some source_domain levels to become singleton, which could make the FE estimation fragile. Match the spirit of 06C's LOO which uses `topic_clean + csto`.)

#### e) Placebo bandwidth (chunk `placebo-prob`, line ~761)

Currently:
```r
bw_placebo <- rdbwselect(y = data_dec$sentiment_clean,
                         x = data_dec$running_probabilistic, ...)
```

Change to:
```r
resid_y_placebo <- feols(sentiment_clean ~ 1 | topic_clean + state_owned,
                         data = data_dec)$residuals
bw_placebo <- rdbwselect(y = resid_y_placebo,
                         x = data_dec$running_probabilistic, ...)
```

#### f) Matched LOO bandwidth (chunk `matched-loo-prob`, line ~1014)

Currently:
```r
rdbwselect(y = data_loo_m$sentiment_clean,
           x = data_loo_m$running_probabilistic, ...)
```

Change to:
```r
resid_y_loo_m <- feols(sentiment_clean ~ 1 | topic_clean + state_owned,
                       data = data_loo_m)$residuals
rdbwselect(y = resid_y_loo_m,
           x = data_loo_m$running_probabilistic, ...)
```

This call is inside a `tryCatch`, so wrap the residualization inside it too, or add its own `tryCatch`.

---

## 3. Consolidate by-topic models: replace `sentiment_clean` with `sentiment_z`, drop separate `_z` variants

### Problem

05C currently has two parallel sets of by-topic models:
- `sentiment_clean` versions (`model2a_full_pol`, `model2a_opt_pol`, etc.) — no FEs, with bootstraps
- `sentiment_z` versions (`model2a_full_pol_z`, `model2a_opt_pol_z`, etc.) — incorrectly using `topic_clean + source_domain` as FEs, using wrong data for the optimal BW variants

In 06C, there is only ONE set of by-topic models per bandwidth, and they use `sentiment_z` with no fixed effects. 05C should match this pattern.

### What to do

#### a) Full-data by-topic models (chunk `topic-full-prob`, lines ~538–588)

**Replace** the `sentiment_clean` models with `sentiment_z` models. Keep the same variable names (no `_z` suffix) to match 06C's convention. **Delete** the separate `_z` variants entirely.

The chunk should become:

```r
data_pol <- data_non_ukraine %>% filter(topic_clean == "Political")
data_mil <- data_non_ukraine %>% filter(topic_clean == "Military")
data_econ <- data_non_ukraine %>% filter(topic_clean == "Economic")
data_cult <- data_non_ukraine %>% filter(topic_clean == "Culture")
data_oth <- data_non_ukraine %>% filter(topic_clean == "Other")

model2a_full_pol <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                          cluster = ~source_domain,
                          data = data_pol)
model2a_full_mil <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                          cluster = ~source_domain,
                          data = data_mil)
model2a_full_econ <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                           cluster = ~source_domain,
                           data = data_econ)
model2a_full_cult <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                           cluster = ~source_domain,
                           data = data_cult)
model2a_full_oth <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                          cluster = ~source_domain,
                          data = data_oth)

# Wild cluster bootstrap for topic-specific models (full data)
boot_model2a_full_pol <- run_wild_bootstrap(model2a_full_pol, "treatment:state_owned")
boot_model2a_full_mil <- run_wild_bootstrap(model2a_full_mil, "treatment:state_owned")
boot_model2a_full_econ <- run_wild_bootstrap(model2a_full_econ, "treatment:state_owned")
boot_model2a_full_cult <- run_wild_bootstrap(model2a_full_cult, "treatment:state_owned")
boot_model2a_full_oth <- run_wild_bootstrap(model2a_full_oth, "treatment:state_owned")
```

Note: No FEs at all — no `topic_clean` (single-level), no `source_domain`. This matches 06C.

**Delete** the entire `model2a_full_pol_z` through `model2a_full_oth_z` block (lines 569–588).

#### b) Per-topic optimal BW models (chunk `topic-opt-models-prob`, lines ~630–683)

Same approach: replace `sentiment_clean` with `sentiment_z`, no FEs, use the bandwidth-restricted data. **Delete** the separate `_z` variants.

The models section should become:

```r
model2a_opt_pol <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                         cluster = ~source_domain,
                         data = opt_data_pol)
model2a_opt_mil <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                         cluster = ~source_domain,
                         data = opt_data_mil)
model2a_opt_econ <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                          cluster = ~source_domain,
                          data = opt_data_econ)
model2a_opt_cult <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                          cluster = ~source_domain,
                          data = opt_data_cult)
model2a_opt_oth <- feols(sentiment_z ~ running_probabilistic * treatment * state_owned,
                         cluster = ~source_domain,
                         data = opt_data_oth)

# Wild cluster bootstrap for topic-specific models (optimal BW)
boot_model2a_opt_pol <- run_wild_bootstrap(model2a_opt_pol, "treatment:state_owned")
boot_model2a_opt_mil <- run_wild_bootstrap(model2a_opt_mil, "treatment:state_owned")
boot_model2a_opt_econ <- run_wild_bootstrap(model2a_opt_econ, "treatment:state_owned")
boot_model2a_opt_cult <- run_wild_bootstrap(model2a_opt_cult, "treatment:state_owned")
boot_model2a_opt_oth <- run_wild_bootstrap(model2a_opt_oth, "treatment:state_owned")
```

**Delete** the entire `model2a_opt_pol_z` through `model2a_opt_oth_z` block (lines 664–683).

#### c) Update the save list (chunk `save-prob`, lines ~1225–1349)

Since the `_z` by-topic variants no longer exist as separate objects, remove them from the save list:

**Remove** these entries:
```r
  # Z-score by-topic (optimal BW)
  model2a_opt_pol_z = model2a_opt_pol_z,
  model2a_opt_mil_z = model2a_opt_mil_z,
  model2a_opt_econ_z = model2a_opt_econ_z,
  model2a_opt_cult_z = model2a_opt_cult_z,
  model2a_opt_oth_z = model2a_opt_oth_z,

  # Z-score by-topic (full data)
  model2a_full_pol_z = model2a_full_pol_z,
  model2a_full_mil_z = model2a_full_mil_z,
  model2a_full_econ_z = model2a_full_econ_z,
  model2a_full_cult_z = model2a_full_cult_z,
  model2a_full_oth_z = model2a_full_oth_z,
```

The existing entries for `model2a_opt_pol`, `model2a_full_pol`, etc. remain — they now point to the `sentiment_z` versions.

#### d) Summary tables (chunks `table2i-topic-opt-prob` and `table2i-topic-full-prob`)

The `modelsummary` calls already reference `model2a_opt_pol`, `model2a_full_pol`, etc. (no `_z` suffix), so the table code itself needs no changes — it will automatically pick up the new `sentiment_z` models. However, update the table **titles** and **notes** to indicate these are z-scored sentiment models. For example:

- Title at line ~1189: add "(Z-Scored Sentiment)" or similar
- Title at line ~1214: same

---

## 4. Minor consistency fixes

### a) Separate RDDs (lines 69–133)

The separate RDDs for state-only and independent-only media use `rdrobust` directly on `running_probabilistic`. Since `running_probabilistic` will now be in days (after change #1), these will automatically be correct. No additional change needed.

### b) Ensure z-score recomputation within bandwidth subsets

After filtering to optimal bandwidth (line ~247–256), the z-score is recomputed within the subset. This is correct and should remain. Similarly check that the z-score recomputation in the `combined-robust-model-prob` chunk (lines 479–483) remains intact. No change needed — just verify.

### c) Effect size chunk (lines 174–186)

The effect size computation divides by `sd_sentiment_non_ukraine`. This is fine and doesn't need changing — it's a standardization step independent of the running variable units.

---

## Summary checklist

- [ ] Convert `running_probabilistic` to days in `data_non_ukraine` and `data` in the load chunk
- [ ] Update all `cat()` bandwidth output strings from "seconds" to "days"
- [ ] Update all plot axis labels from "Hours" to "Days" (including placebo plot: "Seconds" to "Days")
- [ ] Residualize outcome before `rdbwselect` at all 6 locations (main, combined, 5 per-topic, LOO, placebo, matched LOO)
- [ ] Replace full-data by-topic `sentiment_clean` models with `sentiment_z` (no FEs, same variable names)
- [ ] Replace optimal-BW by-topic `sentiment_clean` models with `sentiment_z` using `opt_data_*` (no FEs, same variable names)
- [ ] Delete the separate `_z` by-topic model blocks entirely (both full-data and optimal-BW)
- [ ] Remove the `_z` by-topic entries from the save list
- [ ] Update by-topic summary table titles to reflect z-scored sentiment
