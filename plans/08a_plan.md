# 08a_publication_outputs Plan

## Instructions for Claude Code

This plan builds `08a_publication_outputs.Rmd` — the **primary** publication outputs file using the **probabilistic (KDE) time assignment** data variant.

### Resumability

1. Create `08a_progress.md` in the project root. Initialize with every task below as `- [ ]`.
2. Before each task, read `08a_progress.md`. Skip any `- [x]` task.
3. After completing each task, mark it `- [x]` and save immediately.
4. If resuming after compaction/restart, read `08a_progress.md` and jump to the first unchecked task.
5. If a model is not found in the .rds, insert a `# TODO` comment and mark the task `- [~]`.

### Reference File

The original `08_publication_outputs.Rmd` is available as a reference for model names and code patterns. Do NOT copy code verbatim — write fresh code following the patterns described below, but use the reference to verify model names and bootstrap_se key names.

### Pre-requisite

Before building 08a, add the following to `00_setup.R` (if not already present):

```r
# --- Publication Output Helpers ---

create_bootstrap_vcov <- function(model, boot_result, coef_name) {
  original_vcov <- vcov(model)
  modified_vcov <- original_vcov
  coef_idx <- which(names(coef(model)) == coef_name)
  if (length(coef_idx) > 0 && !is.null(boot_result$se)) {
    modified_vcov[coef_idx, coef_idx] <- boot_result$se^2
  }
  return(modified_vcov)
}

get_boot_stars <- function(p_val) {
  if (is.null(p_val) || is.na(p_val)) return("")
  if (p_val < 0.001) return("***")
  if (p_val < 0.01) return("**")
  if (p_val < 0.05) return("*")
  if (p_val < 0.1) return("+")
  return("")
}

get_n_clusters <- function(mod) {
  if (inherits(mod, "felm")) {
    # felm stores cluster info differently
    tryCatch({
      n <- length(unique(mod$clustervar[[1]]))
      return(as.character(n))
    }, error = function(e) return("—"))
  } else if (inherits(mod, "rdrobust")) {
    return(NA_character_)
  } else {
    return("—")
  }
}

save_table <- function(tbl, name, subdir = NULL) {
  out_dir <- if (!is.null(subdir)) file.path(FIGURES_TABLES, subdir) else FIGURES_TABLES
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  gtsave(tbl, file.path(out_dir, paste0(name, ".tex")))
  gtsave(tbl, file.path(out_dir, paste0(name, ".html")))
  invisible(tbl)
}

SE_NOTE_BOOT <- "† Standard errors computed via wild cluster restricted (WCR) bootstrap (Cameron, Gelbach & Miller 2008) with Webb six-point weights (B=9999, null imposed), clustered by source domain."
SE_NOTE_RDROBUST <- "‡ Cluster-robust SEs from rdrobust."
SE_NOTE_CLUSTER <- "All standard errors are clustered at the source level."
SE_NOTE <- paste(SE_NOTE_BOOT, SE_NOTE_RDROBUST)
```

---

## Table Inventory

### Main Paper Tables (7)

| Table | Hypothesis | Content | Cols | Pattern |
|-------|-----------|---------|------|---------|
| 1 | H1 | RDD hybrid FE + Z-score | 7 | A |
| 2 | H2 | Interaction Z-score | 8 | B |
| 3 | H2 | By-topic Z-score | 5 | C-z |
| 4 | H3a | Interaction Z-score | 7 | B |
| 5 | H3a | By-topic Z-score | 5 | C-z |
| 6 | H3b | Null result Z-score | 5 | B |
| 7 | — | Country classification | 1 | E |

### Supplementary Tables (10)

| Table | Hypothesis | Content | Cols | Pattern |
|-------|-----------|---------|------|---------|
| S1 | H1 | FE robustness | 7 | A |
| S2 | H1 | By-topic Z-score | 5 | C-z |
| S3 | H2 | FE interaction core | 8 | B-fe |
| S4 | H2 | FE robustness (full FE + DID) | 3 | B-fe |
| S5 | H2 | By-topic FE opt BW | 5 | C-fe |
| S6 | H2 | LOO robustness | — | E |
| S7 | H3a | FE interaction + full FE robustness | 9 | B-fe |
| S8 | H3a | By-topic FE opt BW | 5 | C-fe |
| S9 | H3a | LOO robustness | — | E |
| S10 | All | Placebo test summary | — | E |

---

## Pattern Descriptions

### Pattern A: Single-coefficient RDD (no interaction)

Used by: Table 1, S1

- `coef_map = c("treatment" = "Invasion")`
- `fmt = fmt_significant(2)`, `stars = TRUE`
- No bootstrap vcov needed (H1 felm models use cluster-robust SEs; rdrobust models have built-in SEs)
- No star override
- Rows show FE structure (State FEs, Source FEs, Topic FEs, Source Z-Score as appropriate)
- `gof_omit = "BIC|AIC|RMSE|Std.Errors|FE|R2 Within|R2 Within Adj."`

### Pattern B: Interaction with bootstrap vcov (Z-score DV)

Used by: Tables 2, 4, 6

These tables have two coefficient rows (main effect + interaction), columns 1–2 are separate-group rdrobust RDDs, and remaining columns are felm interaction models with bootstrap vcov.

**Structure:**
1. Define the model list and bootstrap keys
2. Build `vcov` list: `NULL` for rdrobust columns, `create_bootstrap_vcov()` for felm columns using the interaction term name
3. Call `modelsummary()` with `stars = TRUE` and the vcov list
4. Post-process with `text_transform()` to override stars on the interaction row using bootstrap `p_val`

**Column naming:** rdrobust columns get `‡` suffix, felm columns get `†` suffix.

**coef_map varies by hypothesis:**
- H2: `c("treatment" = "Invasion", "treatment:state_owned" = "State Owned x Treatment")`
- H3a: `c("treatment" = "Invasion", "treatment:csto" = "CSTO x Treatment")`
- H3b: `c("treatment" = "Invasion", "treatment:high_russia" = "High Russian Pop x Treatment")`

**Bootstrap star override template:**
```r
interaction_row <- 3  # row 1=Invasion est, row 2=Invasion SE, row 3=interaction est
boot_col_names <- paste0("(", first_boot_col:last_boot_col, ")†")

for (i in seq_along(boot_results)) {
  boot_p <- boot_results[[i]]$p_val
  boot_stars <- get_boot_stars(boot_p)
  table <- table %>%
    text_transform(
      locations = cells_body(columns = boot_col_names[i], rows = interaction_row),
      fn = function(x) {
        val <- gsub("[+*]+$", "", x)
        paste0(val, boot_stars)
      }
    )
}
```

**IMPORTANT:** Verify `interaction_row` is correct by checking the gt output structure. It should be row 3 if there are exactly 2 coefficients (Invasion estimate, Invasion SE, Interaction estimate, Interaction SE).

**Rows:** `Source Z-Score = X` for all columns.

### Pattern B-fe: FE Interaction with bootstrap vcov

Used by: S3, S4, S5, S7

Same as Pattern B but:
- All columns are felm (no rdrobust columns)
- All columns get `†` suffix
- All columns need `create_bootstrap_vcov()`
- Rows show FE structure (State FEs, Source FEs, Topic FEs) instead of Source Z-Score
- Bootstrap star override applies to ALL columns, not just 3+

### Pattern C-z: By-topic Z-score (5 columns)

Used by: Tables 3, 5, S2

- 5 columns: Political, Military, Economic, Cultural, Other
- `fmt = fmt_significant(2)`, `stars = TRUE`
- Bootstrap vcov for the interaction term (H2/H3a) or no bootstrap (H1)
- Bootstrap star override on interaction row for H2/H3a tables
- Row: `Source Z-Score = X` for all columns

**For H1 (S2):** `coef_map = c("treatment" = "Invasion")`, no bootstrap, no star override
**For H2 (Table 3):** `coef_map` includes interaction term, bootstrap vcov + star override
**For H3a (Table 5):** same as H2 but with CSTO interaction

### Pattern C-fe: By-topic FE (5 columns)

Used by: S5, S8

Same as C-z but:
- FE-based models, all have bootstrap vcov
- Rows show FE structure
- Bootstrap star override on interaction row

### Pattern E: Custom tables

Used by: Table 7, S6, S9, S10

These are built with `gt()` directly (not `modelsummary`). Each is unique:
- **Table 7 (Country classification):** 2×2 grid of countries by alignment × ethnic Russian population
- **S6, S9 (LOO robustness):** Custom gt from `loo_summary` + `matched_loo_summary` data frames. Show country dropped, coefficient, SE, p-value, N, bandwidth.
- **S10 (Placebo):** Summary table with rows for each hypothesis placebo test.

---

## Phase 1: File Setup

### Task 1.1: Create file header

Create `08a_publication_outputs.Rmd` with YAML header:

```yaml
---
title: "08a - Publication Outputs (Probabilistic Time)"
author: "Donald Moratz"
date: "`r format(Sys.time(), '%B %d, %Y')`"
output:
  html_document:
    toc: true
    toc_float: true
    code_folding: show
---
```

Add overview section explaining this file uses probabilistic (KDE) time assignment.

### Task 1.2: Load data

```r
source("00_setup.R")

TABLE_SUBDIR <- "prob"  # Tables save to FIGURES_TABLES/prob/

results_h1   <- readRDS(file.path(DATA_INTERMEDIATE, "04_h1_results_prob.rds"))
results_h2   <- readRDS(file.path(DATA_INTERMEDIATE, "05_h2_results_prob.rds"))
results_align <- readRDS(file.path(DATA_INTERMEDIATE, "06_alignment_results_prob.rds"))
results_ethnic <- readRDS(file.path(DATA_INTERMEDIATE, "07_ethnic_results_prob.rds"))
data <- readRDS(file.path(DATA_INTERMEDIATE, "02_cleaned_data.rds"))
```

### Task 1.3: Model verification

Add a chunk that checks for the existence of all models referenced in this file. Print OK/WARNING for each. Check at minimum:
- H2 Z-score models: `model2_state_rdd_z`, `model2_ind_rdd_z`, `model2a_z`, `model2a_opt_z`, `model2b_z`, `model2d_z`, `model3a_z`, `matched_model_z`
- H2 bootstrap keys: `bootstrap_se$model2a_z`, `bootstrap_se$model2a_opt_z`, etc.
- H3a Z-score models: `model5a_csto_z`, `model5a_neutral_z`, `model5a_z`, `model5a_opt_z`, `model5a_opt_non_mil_z`, `model5a_opt_russian_z`
- H3a bootstrap keys for Z-score: `bootstrap_se$model5a_z`, `bootstrap_se$model5a_opt_z`, etc.
- H3b models (likely TODO): `model6a_high_z`, `model6a_low_z`, `model6a_opt_z`, etc.

---

## Phase 2: Table 1 — H1 RDD (Pattern A)

### Task 2.1: Build Table 1

7 columns. Uses Pattern A.

| Col | Model | Row indicators |
|-----|-------|---------------|
| (1) | `results_h1$model1_opt` | No FEs |
| (2) | `results_h1$model2_opt` | State |
| (3) | `results_h1$model3_opt` | State + Source |
| (4) | `results_h1$model4_opt` | State + Source + Topic |
| (5) | `results_h1$model5_opt` | Topic + Z-Score |
| (6) | `results_h1$model6a_nonmil` | Topic + Z-Score, non-mil |
| (7) | `results_h1$model7a_nonnato` | Topic + Z-Score, non-NATO |

Rows:
```
Topic FEs:       -  -  -  X  X  X  X
State FEs:       -  X  X  X  -  -  -
Source FEs:      -  -  X  X  -  -  -
Source Z-Score:  -  -  -  -  X  X  X
```

Note: "All standard errors are clustered at the source level. Models 1-4 use the optimal bandwidth. Models 5-7 use a Z-Score adjustment instead of fixed effects. Model 6 omits Military Topics. Model 7 omits NATO allies."

Save as: `table_01_main`

**IMPORTANT:** All `save_table()` calls in this file must pass `TABLE_SUBDIR` as the subdir argument: `save_table(table_1, "table_01_main", TABLE_SUBDIR)`. This applies to every table in the file.

---

## Phase 3: Table 2 — H2 Interaction Z-Score (Pattern B)

### Task 3.1: Build Table 2

8 columns. Uses Pattern B.

| Col | Model | Type | Bootstrap key | Interaction term |
|-----|-------|------|--------------|-----------------|
| (1)‡ | `results_h2$model2_state_rdd_z` | rdrobust | — | — |
| (2)‡ | `results_h2$model2_ind_rdd_z` | rdrobust | — | — |
| (3)† | `results_h2$model2a_z` | felm | `bootstrap_se$model2a_z` | `treatment:state_owned` |
| (4)† | `results_h2$model2a_opt_z` | felm | `bootstrap_se$model2a_opt_z` | `treatment:state_owned` |
| (5)† | `results_h2$model2b_z` | felm | `bootstrap_se$model2b_z` | `treatment:state_owned` |
| (6)† | `results_h2$model2d_z` | felm | `bootstrap_se$model2d_z` | `treatment:state_owned` |
| (7)† | `results_h2$model3a_z` | felm | `bootstrap_se$model3a_z` | `treatment:state_owned` |
| (8)† | `results_h2$matched_model_z` | felm | `bootstrap_se$matched_model_z` | `treatment:state_owned` |

Rows: `Source Z-Score = X` for all columns.

vcov: `NULL` for cols 1-2, `create_bootstrap_vcov()` for cols 3-8.

Post-process: override interaction row stars for cols 3-8 using bootstrap `p_val`.

Note: "All models use a source-level Z-Score normalization. Models 1-2 show separate RDD estimates for state-owned and independent media, filtered to omit military topics. Models 3-8 estimate the state-owned × treatment interaction. Model 3 uses the full dataset. Model 4 uses the optimal bandwidth. Model 5 omits military topics. Model 6 omits NATO allies. Model 7 restricts to Russian-related articles with a re-optimized bandwidth. Model 8 uses matched data. [SE_NOTE]"

Save as: `table_02_main`

---

## Phase 4: Table 3 — H2 By-Topic Z-Score (Pattern C-z)

### Task 4.1: Build Table 3

5 columns. Uses Pattern C-z with H2 interaction.

| Col | Model | Bootstrap key |
|-----|-------|--------------|
| Political | `results_h2$model2a_opt_z_pol` | `bootstrap_se$model2a_opt_z_pol` |
| Military | `results_h2$model2a_opt_z_mil` | `bootstrap_se$model2a_opt_z_mil` |
| Economic | `results_h2$model2a_opt_z_econ` | `bootstrap_se$model2a_opt_z_econ` |
| Cultural | `results_h2$model2a_opt_z_cult` | `bootstrap_se$model2a_opt_z_cult` |
| Other | `results_h2$model2a_opt_z_oth` | `bootstrap_se$model2a_opt_z_oth` |

coef_map: `c("treatment" = "Invasion", "treatment:state_owned" = "State Owned x Treatment")`

All columns get bootstrap vcov for `treatment:state_owned`. Override interaction row stars.

Row: `Source Z-Score = X` for all columns.

**NOTE:** These Z-score by-topic models may not exist yet. Check the results object. If missing, insert TODO and mark task `- [~]`.

Save as: `table_03_main`

---

## Phase 5: Table 4 — H3a Interaction Z-Score (Pattern B)

### Task 5.1: Build Table 4

7 columns. Uses Pattern B.

| Col | Model | Type | Bootstrap key | Interaction term |
|-----|-------|------|--------------|-----------------|
| (1)‡ | `results_align$model5a_csto_z` | rdrobust | — | — |
| (2)‡ | `results_align$model5a_neutral_z` | rdrobust | — | — |
| (3)† | `results_align$model5a_z` | felm | `bootstrap_se$model5a_z` | `treatment:csto` |
| (4)† | `results_align$model5a_opt_z` | felm | `bootstrap_se$model5a_opt_z` | `treatment:csto` |
| (5)† | `results_align$model5a_opt_non_mil_z` | felm | `bootstrap_se$model5a_opt_non_mil_z` | `treatment:csto` |
| (6)† | `results_align$model5a_opt_russian_z` | felm | `bootstrap_se$model5a_opt_russian_z` | `treatment:csto` |
| (7)† | `results_align$matched_model` | felm | `bootstrap_se$matched_model` | `treatment:csto` |

Rows: `Source Z-Score = X` for all columns.

Note: "All models use a source-level Z-Score normalization. Sample restricted to state-owned media in non-NATO countries. Models 1-2 show separate RDD estimates for CSTO-aligned and neutral countries, filtered to omit military topics. Models 3-7 estimate the CSTO × treatment interaction. Model 3 uses the full dataset. Model 4 uses the optimal bandwidth. Model 5 omits military topics. Model 6 restricts to Russian-related articles. Model 7 uses matched data. [SE_NOTE]"

Save as: `table_04_main`

---

## Phase 6: Table 5 — H3a By-Topic Z-Score (Pattern C-z)

### Task 6.1: Build Table 5

5 columns. Same pattern as Table 3 but for H3a.

Models: Z-score by-topic alignment models. Expected names might be `model5a_opt_z_pol` etc. — check results object.

coef_map: `c("treatment" = "Invasion", "treatment:csto" = "CSTO x Treatment")`

Bootstrap vcov for `treatment:csto`. Override interaction row stars.

**NOTE:** These Z-score by-topic models may not exist yet. If missing, insert TODO.

Save as: `table_05_main`

---

## Phase 7: Table 6 — H3b Null Result Z-Score (Pattern B)

### Task 7.1: Build Table 6

5 columns. Uses Pattern B.

| Col | Model | Type | Bootstrap key | Interaction term |
|-----|-------|------|--------------|-----------------|
| (1)‡ | `results_ethnic$model6a_high_z` | rdrobust | — | — |
| (2)‡ | `results_ethnic$model6a_low_z` | rdrobust | — | — |
| (3)† | `results_ethnic$model6a_opt_z` | felm | `bootstrap_se$model6a_opt_z` | `treatment:high_russia` |
| (4)† | `results_ethnic$model6a_opt_non_mil_z` | felm | `bootstrap_se$model6a_opt_non_mil_z` | `treatment:high_russia` |
| (5)† | `results_ethnic$matched_model_z` | felm | `bootstrap_se$matched_model_z` | `treatment:high_russia` |

coef_map: `c("treatment" = "Invasion", "treatment:high_russia" = "High Russian Pop x Treatment")`

**NOTE:** These models likely do not exist yet. Insert TODO and mark `- [~]`.

Save as: `table_06_main`

---

## Phase 8: Table 7 — Country Classification (Pattern E)

### Task 8.1: Build Table 7

Custom gt table showing the 2×2 classification: Ethnic Russian Population (High/Low) × Russia Alignment (CSTO/Neutral). Lists countries in each cell.

Uses `CSTO_COUNTRIES`, `NEUTRAL_COUNTRIES`, `HIGH_RUSSIAN_POP`, `LOW_RUSSIAN_POP` constants from `00_setup.R`.

See original file's `comparison-table` chunk for reference.

Save as: `table_07_classification`

---

## Phase 9: S1 — H1 FE Robustness (Pattern A)

### Task 9.1: Build Table S1

7 columns, all felm, no bootstrap needed.

| Col | Model | FEs |
|-----|-------|-----|
| (1) | `results_h1$model1_basic` | None |
| (2) | `results_h1$model1_country_fe` | State |
| (3) | `results_h1$model1_country_source_fe` | State + Source |
| (4) | `results_h1$model1_full_linear` | State + Source + Topic |
| (5) | `results_h1$model1_z` | Topic + Z-Score |
| (6) | `results_h1$model6_non_mil` | State + Source + Topic, non-mil |
| (7) | `results_h1$model7_non_nato` | State + Source + Topic, non-NATO |

Rows:
```
Topic FEs:       -  -  -  X  X  X  X
State FEs:       -  X  X  X  -  X  X
Source FEs:      -  -  X  X  -  X  X
Source Z-Score:  -  -  -  -  X  -  -
```

Note: "All standard errors are clustered at the source level. Models 1-4 use the full dataset with progressively added fixed effects. Model 5 uses a Z-Score normalization with the full dataset. Models 6-7 use full fixed effects, restricting to non-military topics and non-NATO countries respectively."

Save as: `table_s01_fe_robustness`

---

## Phase 10: S2 — H1 By-Topic Z-Score (Pattern C-z, no interaction)

### Task 10.1: Build Table S2

5 columns. No interaction term, no bootstrap.

| Col | Model |
|-----|-------|
| Political | `results_h1$model5_opt_pol` |
| Military | `results_h1$model5_opt_mil` |
| Economic | `results_h1$model5_opt_econ` |
| Cultural | `results_h1$model5_opt_cult` |
| Other | `results_h1$model5_opt_oth` |

coef_map: `c("treatment" = "Invasion")`

Row: `Source Z-Score = X` for all columns.

Save as: `table_s02_h1_z_topic`

---

## Phase 11: S3 — H2 FE Interaction Core (Pattern B-fe)

### Task 11.1: Build Table S3

8 columns, all felm, all have bootstrap SEs.

| Col | Model | Bootstrap key | FEs |
|-----|-------|--------------|-----|
| (1)† | `results_h2$model2a` | `bootstrap_se$model2a` | State + Topic |
| (2)† | `results_h2$model2a_full` | `bootstrap_se$model2a_full` | State + Source + Topic |
| (3)† | `results_h2$model2a_opt` | `bootstrap_se$model2a_opt` | State + Topic, opt BW |
| (4)† | `results_h2$model2a_opt_full_fe` | `bootstrap_se$model2a_opt_full_fe` | State + Source + Topic, opt BW |
| (5)† | `results_h2$model2b` | `bootstrap_se$model2b` | State + Topic, non-mil |
| (6)† | `results_h2$model2d` | `bootstrap_se$model2d` | State + Topic, non-NATO |
| (7)† | `results_h2$model3a_opt` | `bootstrap_se$model3a_opt` | State + Topic, Russian |
| (8)† | `results_h2$matched_model` | `bootstrap_se$matched_model` | State + Topic, matched |

Interaction term: `treatment:state_owned`

coef_map: `c("treatment" = "Invasion", "treatment:state_owned" = "State Owned x Treatment")`

Rows: State FEs, Source FEs, Topic FEs with X/- as appropriate. Clusters row.

All columns get bootstrap vcov. Override interaction row stars for all columns.

Save as: `table_s03_h2_fe_core`

---

## Phase 12: S4 — H2 FE Robustness (Pattern B-fe)

### Task 12.1: Build Table S4

3 columns, all felm, all have bootstrap SEs.

| Col | Model | Bootstrap key | Description |
|-----|-------|--------------|-------------|
| (1)† | `results_h2$model2b_full_fe` | `bootstrap_se$model2b_full_fe` | Non-mil, full FEs |
| (2)† | `results_h2$model3a_opt_full_fe` | `bootstrap_se$model3a_opt_full_fe` | Russian, full FEs |
| (3)† | `results_h2$model_did` | `bootstrap_se$model_did` | DID within bandwidth |

Interaction term: `treatment:state_owned`

Note: Verify that `model_did` uses `treatment:state_owned` as the interaction term. If different, adjust accordingly.

Save as: `table_s04_h2_fe_robustness`

---

## Phase 13: S5 — H2 By-Topic FE Opt BW (Pattern C-fe)

### Task 13.1: Build Table S5

5 columns, all felm, all have bootstrap SEs.

| Col | Model | Bootstrap key |
|-----|-------|--------------|
| Political | `results_h2$model2a_opt_pol` | `bootstrap_se$model2a_opt_pol` |
| Military | `results_h2$model2a_opt_mil` | `bootstrap_se$model2a_opt_mil` |
| Economic | `results_h2$model2a_opt_econ` | `bootstrap_se$model2a_opt_econ` |
| Cultural | `results_h2$model2a_opt_cult` | `bootstrap_se$model2a_opt_cult` |
| Other | `results_h2$model2a_opt_oth` | `bootstrap_se$model2a_opt_oth` |

Interaction term: `treatment:state_owned`

Rows: State FEs, Source FEs (probably -), Topic FEs (-). Clusters.

Save as: `table_s05_h2_fe_topic`

---

## Phase 14: S6 — H2 LOO Robustness (Pattern E)

### Task 14.1: Build Table S6

Custom gt table combining `results_h2$loo_summary` and `results_h2$matched_loo_summary`.

Format each as rows showing: country dropped, coefficient, SE, p-value, N, bandwidth. Add a group header distinguishing "Standard Model" from "Matched Model" sections.

See original file's `loo-table` chunk for reference pattern.

Save as: `table_s06_h2_loo`

---

## Phase 15: S7 — H3a FE Interaction + Robustness (Pattern B-fe)

### Task 15.1: Build Table S7

9 columns, all felm, all have bootstrap SEs.

| Col | Model | Bootstrap key |
|-----|-------|--------------|
| (1)† | `results_align$model5a_full` | `bootstrap_se$model5a_full` |
| (2)† | `results_align$model5a_opt` | `bootstrap_se$model5a_opt` |
| (3)† | `results_align$model5a_opt_non_mil` | `bootstrap_se$model5a_opt_non_mil` |
| (4)† | `results_align$model5a_opt_russian` | `bootstrap_se$model5a_opt_russian` |
| (5)† | `results_align$model5a_opt_full_fe` | `bootstrap_se$model5a_opt_full_fe` |
| (6)† | `results_align$matched_model` | `bootstrap_se$matched_model` |
| (7)† | `results_align$model5a_opt_non_mil_full_fe` | `bootstrap_se$model5a_opt_non_mil_full_fe` |
| (8)† | `results_align$model5a_opt_rus_full_fe` | `bootstrap_se$model5a_opt_rus_full_fe` |
| (9)† | `results_align$model5a_fully_saturated` | `bootstrap_se$model5a_fully_saturated` |

Interaction term: `treatment:csto`

coef_map: `c("treatment" = "Invasion", "treatment:csto" = "CSTO x Treatment")`

Rows: State FEs, Source FEs, Topic FEs, Matched — with X/- as appropriate for each column. Clusters.

Save as: `table_s07_h3a_fe_core`

---

## Phase 16: S8 — H3a By-Topic FE Opt BW (Pattern C-fe)

### Task 16.1: Build Table S8

5 columns, all felm, all have bootstrap SEs.

| Col | Model | Bootstrap key |
|-----|-------|--------------|
| Political | `results_align$model5a_opt_pol` | `bootstrap_se$model5a_opt_pol` |
| Military | `results_align$model5a_opt_mil` | `bootstrap_se$model5a_opt_mil` |
| Economic | `results_align$model5a_opt_econ` | `bootstrap_se$model5a_opt_econ` |
| Cultural | `results_align$model5a_opt_cult` | `bootstrap_se$model5a_opt_cult` |
| Other | `results_align$model5a_opt_oth` | `bootstrap_se$model5a_opt_oth` |

Interaction term: `treatment:csto`

Save as: `table_s08_h3a_fe_topic`

---

## Phase 17: S9 — H3a LOO Robustness (Pattern E)

### Task 17.1: Build Table S9

Same pattern as S6 but using `results_align$loo_summary` and `results_align$matched_loo_summary`.

Save as: `table_s09_h3a_loo`

---

## Phase 18: S10 — Placebo Test Summary (Pattern E)

### Task 18.1: Build Table S10

Custom gt table summarizing placebo tests across all hypotheses.

Rows:
1. H1 placebo (FE): `results_h1$model_placebo` (rdrobust — extract from `$coef`, `$se`, `$pv`)
2. H1 placebo (Z-score): `results_h1$model_placebo_z` (rdrobust)
3. H2 placebo: `results_h2$model_placebo` (felm — extract from `summary()$coef`)
4. H3a placebo: `results_align$model_placebo_nonmil` (felm)

Columns: Model, Estimate, Std. Error, p-value, Bandwidth, N

See original file's `placebo-summary` chunk for reference.

Save as: `table_s10_placebo`

---

## Phase 19: Summary and Session Info

### Task 19.1: Add summary section

Print a summary listing all tables generated with their filenames.

### Task 19.2: Add session info

```r
print_session_info()
```

---

## Creating 08b, 08c, 08d

**STOP HERE.** Once 08a is complete and validated, pause and inform the user:

> "08a is complete. All [N] phases done, [N] tables generated. Please review the output, then switch to Sonnet and re-run to continue with 08b-08d."

Do NOT proceed to 08b-08d in the same session. The user will switch to Sonnet and restart.

Once restarted with Sonnet:

### 08b — Day Running Variable

1. Copy `08a_publication_outputs.Rmd` to `08b_publication_outputs_days.Rmd`
2. Update title to "Publication Outputs (Day Running Variable)"
3. Change `TABLE_SUBDIR <- "prob"` to `TABLE_SUBDIR <- "days"`
4. Find-replace in the load section:
   - `04_h1_results_prob.rds` → `04_h1_results.rds`
   - `05_h2_results_prob.rds` → `05_h2_results.rds`
   - `06_alignment_results_prob.rds` → `06_alignment_results.rds`
   - `07_ethnic_results_prob.rds` → `07_ethnic_results.rds`
5. Update all table titles: change "(Probabilistic Time)" to "(Day Running Variable)"

### 08c — Continuous Running Variable

Same process but:
- `TABLE_SUBDIR <- "continuous"`
- Use `*_continuous.rds` files
- Title: "(Continuous Running Variable)"

### 08d — Drop No-Time Articles

Same process but:
- `TABLE_SUBDIR <- "drop"`
- Use `*_drop.rds` files
- Title: "(Drop No-Time Articles)"

**IMPORTANT for 08c and 08d:** Some models may not exist in all data variants. Any model not found should get a TODO comment. The file structure must remain identical so tables can be compared across variants.

### Model Assignment

- **08a:** Use Opus (accuracy matters for getting the bootstrap vcov wiring and star override logic right)
- **08b, 08c, 08d:** Use Sonnet (mechanical find-and-replace duplication, low interpretation risk)

---

## Phase 20: Update master.Rmd

### Task 20.1: Update master.Rmd

After all four files (08a–08d) are created, update `master.Rmd` to include the new file structure. The old single `08_publication_outputs.Rmd` entry should be replaced with:

```
08a_publication_outputs.Rmd       — Publication tables (Probabilistic Time, primary)
08b_publication_outputs_days.Rmd  — Publication tables (Day Running Variable)
08c_publication_outputs_cont.Rmd  — Publication tables (Continuous Running Variable)
08d_publication_outputs_drop.Rmd  — Publication tables (Drop No-Time Articles)
```

Match the existing format and conventions used in `master.Rmd` for listing scripts. If the master script renders/sources each file, add the appropriate render or source calls for all four new files and remove the old `08_publication_outputs.Rmd` reference.
