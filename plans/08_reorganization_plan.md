# 08_publication_outputs.Rmd — Reorganization Plan

## Instructions for Claude Code

This document specifies how to reorganize `08_publication_outputs.Rmd`. Before starting work:

1. **Create a progress tracker** at `08_reorganization_progress.md` in the same directory as this file. Initialize it with every task listed below, each as an unchecked `- [ ]` item. 
2. **Before each task**, read `08_reorganization_progress.md`. Skip any task already marked `- [x]`.
3. **After completing each task**, immediately update the tracker to `- [x]` and save.
4. **If you are resuming after a context compaction or session restart**, read `08_reorganization_progress.md` first to find where you left off. Do not re-read this entire plan — jump to the first unchecked task.
5. **Do not create models that don't exist.** If a task references a model object that is not present in the loaded .rds files, insert a clearly marked `# TODO: Model [name] not found in [results_object] — create in [script] before enabling this table` comment and skip that table. Mark the task as `- [~]` (partial) in the tracker.
6. **Validate after each phase.** After completing all tasks in a phase, check that the Rmd file parses correctly (no unclosed code chunks, no syntax errors). You can do this by scanning for matched ` ```{r ...} ` and ` ``` ` pairs.

---

## Table Numbering System

### Main Paper Tables

Tables 1–4, one per hypothesis. Each exists in 4 data variants:

| Suffix | Data variant | Source objects |
|--------|-------------|---------------|
| *(none)* | Day running variable | `results_h1`, `results_h2`, `results_align`, `results_ethnic` |
| **(Prob)** | Probabilistic time assignment | `results_h1_prob`, `results_h2_prob`, `results_align_prob`, `results_ethnic_prob` |
| **(Cont)** | Continuous (seconds) running variable | `results_h1_cont`, `results_h2_cont`, `results_align_cont`, `results_ethnic_cont` |
| **(Drop)** | Drop no-time articles | `results_h1_drop`, `results_h2_drop`, `results_align_drop`, `results_ethnic_drop` |

So "Table 2 (Prob)" means the H2 diff-in-disc table using probabilistic time data.

### Supplementary Tables

Same suffix convention. "Table S3 (Cont)" means supplementary table S3 using continuous data.

| Table | Content |
|-------|---------|
| S1 | H1 FE-based main results |
| S2 | H2 FE-based main results |
| S3 | H3a Alignment FE-based main results |
| S4 | H3b Ethnic FE-based main results |
| S5 | H1 by-topic, Z-Score, optimal BW |
| S6 | H2 by-topic, Z-Score, optimal BW |
| S7 | H3a by-topic, Z-Score, optimal BW |
| S8 | H3b by-topic, Z-Score, optimal BW |
| S9 | H1 by-topic, FE, optimal BW |
| S10 | H2 by-topic, FE, optimal BW |
| S11 | H3a by-topic, FE, optimal BW |
| S12 | H3b by-topic, FE, optimal BW |
| S13 | H2 by-topic, FE, full data |
| S14 | H3a by-topic, FE, full data |
| S15 | H3b by-topic, FE, full data |
| S16 | H2 Full FE robustness |
| S17 | H2 State vs. Independent separate RDDs (FE) |
| S18 | Country classification |
| S19 | Alignment classification |
| S20 | Ethnic population classification |
| S21 | Leave-one-out country robustness |
| S22 | Placebo test summary |

Each of S1–S17 has 4 data variants (no suffix, Prob, Cont, Drop). S18–S22 are standalone (no variants).

---

## Standard Error Notes

All tables need accurate SE footnotes. Use the following:

**For FE-based tables using bootstrap SEs (everything except pure rdrobust models and Z-score models):**
```r
SE_NOTE_BOOT <- "† Standard errors computed via wild cluster restricted (WCR) bootstrap (Cameron, Gelbach & Miller 2008) with Webb six-point weights (B=9999, null imposed), clustered by source domain."
```

**For tables containing rdrobust models (e.g., columns 1-2 of Tables 3 and 4 showing separate RDDs):**
Append: `"Models N-M use cluster-robust SEs from rdrobust."`

**For pure Z-score tables where SEs come from felm cluster-robust (not bootstrap):**
Use: `"All standard errors are clustered at the source level."` (no bootstrap note needed — verify this is correct for the Z-score models; if they also use bootstrap, use the WCR note instead).

**UPDATE the existing `SE_NOTE` constant** in the helper section to reflect the WCR/Webb description. The current text says "Wild cluster bootstrap SEs (B=9999, Rademacher, null imposed)" — this should be updated to reference WCR with Webb six-point weights. Split into three constants:

```r
SE_NOTE_BOOT <- "† Standard errors computed via wild cluster restricted (WCR) bootstrap (Cameron, Gelbach & Miller 2008) with Webb six-point weights (B=9999, null imposed), clustered by source domain."
SE_NOTE_RDROBUST <- "‡ Cluster-robust SEs from rdrobust."
SE_NOTE_CLUSTER <- "All standard errors are clustered at the source level."
```

---

## Methodological Rationale (for reference — do not include in Rmd)

Table 1 (H1) uses a **hybrid** structure: columns 1–4 progressively add fixed effects, columns 5–7 use source-level Z-score normalization. This demonstrates that FE and Z-score approaches converge when both are feasible.

Tables 2–4 (H2, H3a, H3b) use **pure Z-score** structures because the grouping variables (state-owned/independent, CSTO/neutral, high/low ethnic Russian pop) are nested within source, making source FEs collinear with the interaction term.

---

## Phase 1: Setup and Infrastructure

### Task 1.1: Update file header and overview

Replace the Overview section with updated text reflecting the new table organization. Mention the numbering system and data variant convention. Update the Inputs list (same files) and Outputs description.

### Task 1.2: Update SE_NOTE constants

In the `save-table-helper` chunk, replace the single `SE_NOTE` with three constants:

```r
SE_NOTE_BOOT <- "† Standard errors computed via wild cluster restricted (WCR) bootstrap (Cameron, Gelbach & Miller 2008) with Webb six-point weights (B=9999, null imposed), clustered by source domain."
SE_NOTE_RDROBUST <- "‡ Cluster-robust SEs from rdrobust."
SE_NOTE_CLUSTER <- "All standard errors are clustered at the source level."
```

Then search-and-replace all downstream references to `SE_NOTE` with the appropriate new constant.

### Task 1.3: Verify model availability

Add a new code chunk after `load` called `verify-models` that checks whether key models exist in each results object. Print warnings for any missing models. Check for:
- `results_h2$model2_state_rdd_z`
- `results_h2$model2_ind_rdd_z`
- Z-score by-topic models in H1: `results_h1$model5_opt_pol` (etc.) — these likely exist
- Z-score by-topic models in H2: check for `results_h2$model2a_opt_z_pol` or similar naming
- Z-score by-topic models in H3a: check for `results_align$model5a_opt_z_pol` or similar naming
- Any Z-score models in `results_ethnic`

Use this pattern for each check:
```r
check_model <- function(obj, name, label) {
  if (is.null(obj[[name]])) {
    cat(sprintf("WARNING: %s$%s not found — table will be skipped\n", label, name))
  } else {
    cat(sprintf("OK: %s$%s\n", label, name))
  }
}
```

---

## Phase 2: Main Paper Tables (Day Running Variable)

### Task 2.1: Table 1 — H1 RDD (Days)

Replace the current `table1` chunk with the new hybrid design. 7 columns:

| Col | Model object | Description |
|-----|-------------|-------------|
| (1) | `results_h1$model1_opt` | No FEs, optimal BW |
| (2) | `results_h1$model2_opt` | + State FEs |
| (3) | `results_h1$model3_opt` | + Source FEs |
| (4) | `results_h1$model4_opt` | + Topic FEs |
| (5) | `results_h1$model5_opt` | Z-Score, optimal BW |
| (6) | `results_h1$model6a_nonmil` | Z-Score, non-military |
| (7) | `results_h1$model7a_nonnato` | Z-Score, non-NATO |

```r
rows <- tibble::tribble(
  ~term, ~row1, ~row2, ~row3, ~row4, ~row5, ~row6, ~row7,
  'Topic FEs', '-', '-', '-', 'X', 'X', 'X', 'X',
  'State FEs', '-', 'X', 'X', 'X', '-', '-', '-',
  'Source FEs', '-', '-', 'X', 'X', '-', '-', '-',
  'Source Z-Score', '-', '-', '-', '-', 'X', 'X', 'X'
)
attr(rows, 'position') <- c(3, 4, 5, 6)

note_text <- paste("All standard errors are clustered at the source level.",
                   "Models 1-4 use the optimal bandwidth.",
                   "Models 5-7 use a Z-Score adjustment instead of fixed effects.",
                   "Model 6 omits Military Topics. Model 7 omits NATO allies.")

table_1 <- modelsummary(
  list(
    "(1)" = results_h1$model1_opt,
    "(2)" = results_h1$model2_opt,
    "(3)" = results_h1$model3_opt,
    "(4)" = results_h1$model4_opt,
    "(5)" = results_h1$model5_opt,
    "(6)" = results_h1$model6a_nonmil,
    "(7)" = results_h1$model7a_nonnato
  ),
  output = "gt",
  fmt = fmt_significant(2),
  stars = TRUE,
  coef_map = c("treatment" = "Invasion"),
  gof_omit = "BIC|AIC|RMSE|Std.Errors",
  title = "Table 1: Effect of Russian Invasion on Media Sentiment (RDD, Day Running Variable)",
  add_rows = rows,
  notes = str_wrap(note_text, 80)
)

table_1
save_table(table_1, "table_01_main")
```

**NOTE on formatting:** Table 1 uses `fmt = fmt_significant(2)` and `stars = TRUE` (the author's preferred style). Standardize all tables to match this format. If this causes issues with specific supplementary FE tables (e.g., bootstrap vcov display), flag it and keep `fmt = 3` for those.

### Task 2.2: Table 2 — H2 Diff-in-Disc (Days)

Replace the current `table2` chunk. Pure Z-score, 7 columns:

| Col | Model object | Description |
|-----|-------------|-------------|
| (1) | `results_h2$model2_state_rdd_z` | State media RDD, Z-Score |
| (2) | `results_h2$model2_ind_rdd_z` | Independent media RDD, Z-Score |
| (3) | `results_h2$model2a_z` | Interaction, full data |
| (4) | `results_h2$model2a_opt_z` | Interaction, optimal BW |
| (5) | `results_h2$model2b_z` | Non-military topics |
| (6) | `results_h2$model2d_z` | Non-NATO allies |
| (7) | `results_h2$model3a_opt_z` | Russian-related subset |

```r
rows <- tibble::tribble(
  ~term, ~row1, ~row2, ~row3, ~row4, ~row5, ~row6, ~row7,
  'Source Z-Score', 'X', 'X', 'X', 'X', 'X', 'X', 'X'
)
attr(rows, 'position') <- c(5)  # after Invasion + SE + Interaction + SE

note_text <- paste(
  "All models use a source-level Z-Score normalization.",
  "Models 1-2 show separate RDD estimates for state-owned and independent media.",
  "Models 3-7 estimate the state-owned × treatment interaction.",
  "Model 3 uses the full dataset. Model 4 uses the optimal bandwidth.",
  "Model 5 omits military topics. Model 6 omits NATO allies.",
  "Model 7 restricts to Russian-related articles with a re-optimized bandwidth.",
  SE_NOTE_CLUSTER
)

table_2 <- modelsummary(
  list(
    "(1)" = results_h2$model2_state_rdd_z,
    "(2)" = results_h2$model2_ind_rdd_z,
    "(3)" = results_h2$model2a_z,
    "(4)" = results_h2$model2a_opt_z,
    "(5)" = results_h2$model2b_z,
    "(6)" = results_h2$model2d_z,
    "(7)" = results_h2$model3a_opt_z
  ),
  output = "gt",
  fmt = fmt_significant(2),
  stars = TRUE,
  coef_map = c(
    "treatment" = "Invasion",
    "treatment:state_owned" = "State Owned x Treatment"
  ),
  gof_omit = "BIC|AIC|RMSE|Std.Errors|FE",
  title = "Table 2: Difference in Discontinuities — State vs. Independent Media (Day Running Variable)",
  add_rows = rows,
  notes = str_wrap(note_text, 80)
)

table_2
save_table(table_2, "table_02_main")
```

If `model2_state_rdd_z` or `model2_ind_rdd_z` are not found in the results object, insert a TODO comment and skip.

### Task 2.3: Table 3 — H3a Alignment (Days)

Replace the current `table3` chunk. Pure Z-score, 6 columns:

| Col | Model object | Description |
|-----|-------------|-------------|
| (1) | `results_align$model5a_csto_z` | CSTO RDD, Z-Score |
| (2) | `results_align$model5a_neutral_z` | Neutral RDD, Z-Score |
| (3) | `results_align$model5a_z` | Interaction, full data |
| (4) | `results_align$model5a_opt_z` | Interaction, optimal BW |
| (5) | `results_align$model5a_opt_non_mil_z` | Non-military topics |
| (6) | `results_align$model5a_opt_russian_z` | Russian-related subset |

```r
rows <- tibble::tribble(
  ~term, ~row1, ~row2, ~row3, ~row4, ~row5, ~row6,
  'Source Z-Score', 'X', 'X', 'X', 'X', 'X', 'X'
)
attr(rows, 'position') <- c(5)

note_text <- paste(
  "All models use a source-level Z-Score normalization.",
  "Models 1-2 show separate RDD estimates for CSTO-aligned and neutral countries.",
  "Models 3-6 estimate the CSTO × treatment interaction.",
  "Model 3 uses the full dataset. Model 4 uses the optimal bandwidth.",
  "Model 5 omits military topics.",
  "Model 6 restricts to Russian-related articles with a re-optimized bandwidth.",
  "Sample restricted to state-owned media in non-NATO countries.",
  SE_NOTE_CLUSTER
)

table_3 <- modelsummary(
  list(
    "(1)" = results_align$model5a_csto_z,
    "(2)" = results_align$model5a_neutral_z,
    "(3)" = results_align$model5a_z,
    "(4)" = results_align$model5a_opt_z,
    "(5)" = results_align$model5a_opt_non_mil_z,
    "(6)" = results_align$model5a_opt_russian_z
  ),
  output = "gt",
  fmt = fmt_significant(2),
  stars = TRUE,
  coef_map = c(
    "treatment" = "Invasion",
    "treatment:csto" = "CSTO x Treatment"
  ),
  gof_omit = "BIC|AIC|RMSE|Std.Errors|FE",
  title = "Table 3: Russian Alignment Heterogeneity — State Media (Day Running Variable)",
  add_rows = rows,
  notes = str_wrap(note_text, 80)
)

table_3
save_table(table_3, "table_03_main")
```

### Task 2.4: Table 4 — H3b Ethnic (Days)

Replace the current `table4` chunk. Pure Z-score, 6 columns. **This table will almost certainly require TODO markers since the ethnic Z-score models likely do not yet exist.**

| Col | Model object (expected names) | Description |
|-----|------|-------------|
| (1) | `results_ethnic$model6a_high_z` | High ethnic Russian pop RDD, Z-Score |
| (2) | `results_ethnic$model6a_low_z` | Low ethnic Russian pop RDD, Z-Score |
| (3) | `results_ethnic$model6a_z` | Interaction, full data |
| (4) | `results_ethnic$model6a_opt_z` | Interaction, optimal BW |
| (5) | `results_ethnic$model6a_opt_non_mil_z` | Non-military topics |
| (6) | `results_ethnic$model6a_opt_russian_z` | Russian-related subset |

Use the same structure as Table 3 but with:
- `coef_map = c("treatment" = "Invasion", "treatment:high_russia" = "High Russian Pop x Treatment")`
- Title: `"Table 4: Ethnic Russian Population Heterogeneity — State Media (Day Running Variable)"`
- Note referencing high/low ethnic Russian population instead of CSTO/neutral

If models are not found, insert:
```r
# TODO: Table 4 requires Z-score models to be created in 07_ethnic scripts.
# Expected model names: model6a_high_z, model6a_low_z, model6a_z, model6a_opt_z,
# model6a_opt_non_mil_z, model6a_opt_russian_z
# These should mirror the Z-score model structure in 06_alignment scripts.
# Once created, uncomment the code below.
```

File saved as: `table_04_main`

---

## Phase 3: Main Paper Tables — Probabilistic Variant

For each task below: duplicate the corresponding Day table code from Phase 2, but replace the results object with the `_prob` variant, update the title to include "(Prob)", and update the save filename to include `_prob`.

### Task 3.1: Table 1 (Prob)
- Source: `results_h1_prob`
- Title: `"Table 1 (Prob): Effect of Russian Invasion on Media Sentiment (RDD, Probabilistic Time)"`
- File: `table_01_main_prob`
- Chunk name: `table1-prob`

### Task 3.2: Table 2 (Prob)
- Source: `results_h2_prob`
- Title: `"Table 2 (Prob): Difference in Discontinuities — State vs. Independent Media (Probabilistic Time)"`
- File: `table_02_main_prob`

### Task 3.3: Table 3 (Prob)
- Source: `results_align_prob`
- Title: `"Table 3 (Prob): Russian Alignment Heterogeneity — State Media (Probabilistic Time)"`
- File: `table_03_main_prob`

### Task 3.4: Table 4 (Prob)
- Source: `results_ethnic_prob`
- Title: `"Table 4 (Prob): Ethnic Russian Population Heterogeneity — State Media (Probabilistic Time)"`
- File: `table_04_main_prob`

---

## Phase 4: Main Paper Tables — Continuous Variant

### Task 4.1: Table 1 (Cont)
- Source: `results_h1_cont`
- Title: `"Table 1 (Cont): ... (Continuous Running Variable)"`
- File: `table_01_main_cont`

### Task 4.2: Table 2 (Cont)
- Source: `results_h2_cont`. File: `table_02_main_cont`

### Task 4.3: Table 3 (Cont)
- Source: `results_align_cont`. File: `table_03_main_cont`

### Task 4.4: Table 4 (Cont)
- Source: `results_ethnic_cont`. File: `table_04_main_cont`

---

## Phase 5: Main Paper Tables — Drop No-Time Variant

### Task 5.1: Table 1 (Drop)
- Source: `results_h1_drop`. File: `table_01_main_drop`

### Task 5.2: Table 2 (Drop)
- Source: `results_h2_drop`. File: `table_02_main_drop`

### Task 5.3: Table 3 (Drop)
- Source: `results_align_drop`. File: `table_03_main_drop`

### Task 5.4: Table 4 (Drop)
- Source: `results_ethnic_drop`. File: `table_04_main_drop`

---

## Phase 6: Supplementary Tables S1–S4 — FE-Based Main Results

These preserve the current FE-based table designs. Each has 4 data variants. For each task, create the Days variant first, then duplicate for Prob, Cont, and Drop with appropriate source object and title/filename suffixes.

### Task 6.1: Table S1 — H1 FE-based main (all 4 variants)

**S1 (Days):** Reuse the OLD Table 1 code (the FE-based version that Phase 2 replaced). 7 columns: `model1_opt, model2_opt, model3_opt, model4_opt, model1_full_linear, model4_non_mil, model4_non_nato` from `results_h1`.
- Include cluster counts, FE rows (State/Source/Topic), bootstrap vcov where applicable.
- Title: `"Table S1: H1 RDD — Fixed Effects (Day Running Variable)"`
- File: `table_s01_fe_days`

**S1 (Prob):** Same from `results_h1_prob`. Title includes "(Prob)". File: `table_s01_fe_prob`
**S1 (Cont):** Same from `results_h1_cont`. Note: continuous variant also has `model4_felm_saturated` as an 8th column. File: `table_s01_fe_cont`
**S1 (Drop):** Same from `results_h1_drop`. Also has 8th column if available. File: `table_s01_fe_drop`

### Task 6.2: Table S2 — H2 FE-based main (all 4 variants)

**S2 (Days):** Current Table 2 structure: 8 columns (`model2a, model2a_full, model2a_opt, model2a_opt_full_fe, model2b, model2d, model3a_opt, model3a_opt_saturated`) from `results_h2`.
- Title: `"Table S2: H2 Diff-in-Disc — Fixed Effects (Day Running Variable)"`
- File: `table_s02_fe_days`

**S2 (Prob), S2 (Cont), S2 (Drop):** Same pattern from respective result objects.

### Task 6.3: Table S3 — H3a FE-based main (all 4 variants)

**S3 (Days):** Current Table 3 structure: 10 columns from `results_align` including CSTO/neutral RDDs, full, opt, non-mil, Russian, full FE, non-mil full FE, saturated, matched. Include bootstrap vcov.
- Title: `"Table S3: H3a Alignment — Fixed Effects (Day Running Variable)"`
- File: `table_s03_fe_days`

**S3 (Prob), S3 (Cont), S3 (Drop):** Same pattern.

### Task 6.4: Table S4 — H3b FE-based main (all 4 variants)

**S4 (Days):** Current Table 4 structure: 4 columns from `results_ethnic`. Include bootstrap vcov.
- Title: `"Table S4: H3b Ethnic — Fixed Effects (Day Running Variable)"`
- File: `table_s04_fe_days`

**S4 (Prob), S4 (Cont), S4 (Drop):** Same pattern.

---

## Phase 7: Supplementary Tables S5–S8 — By-Topic Z-Score

These are **new tables** that may require models that don't yet exist. Check availability; insert TODO if missing.

### Task 7.1: Table S5 — H1 by-topic Z-Score (all 4 variants)

5 columns: Political, Military, Economic, Cultural, Other.
Models: `model5_opt_pol, model5_opt_mil, model5_opt_econ, model5_opt_cult, model5_opt_oth`

```r
coef_map = c("treatment" = "Invasion")
```

Row: `'Source Z-Score' = 'X'` for all columns.

**S5 (Days):** From `results_h1`. Title: `"Table S5: H1 RDD by Topic — Z-Score (Day Running Variable)"`. File: `table_s05_z_topic_days`
**S5 (Prob):** From `results_h1_prob`. File: `table_s05_z_topic_prob`
**S5 (Cont):** From `results_h1_cont`. File: `table_s05_z_topic_cont`
**S5 (Drop):** From `results_h1_drop`. File: `table_s05_z_topic_drop`

### Task 7.2: Table S6 — H2 by-topic Z-Score (all 4 variants)

Check for Z-score by-topic models in H2 results. Expected names might be `model2a_opt_z_pol` or similar — examine the results object to find the actual names.

```r
coef_map = c("treatment" = "Invasion", "treatment:state_owned" = "State Owned x Treatment")
```

**If models don't exist:** Insert TODO and mark as partial.

### Task 7.3: Table S7 — H3a by-topic Z-Score (all 4 variants)

Check for Z-score by-topic models in alignment results. Expected names might be `model5a_opt_z_pol` or similar.

```r
coef_map = c("treatment" = "Invasion", "treatment:csto" = "CSTO x Treatment")
```

### Task 7.4: Table S8 — H3b by-topic Z-Score (all 4 variants)

These will almost certainly need TODO markers (ethnic Z-score models don't exist yet).

---

## Phase 8: Supplementary Tables S9–S12 — By-Topic FE Optimal BW

These are the existing by-topic FE tables, relocated and renumbered. Each has 4 data variants.

### Task 8.1: Table S9 — H1 by-topic FE opt BW (all 4 variants)

**S9 (Days):** Current Table 1B code. Models: `model4_opt_pol, model4_opt_mil, model4_opt_econ, model4_opt_cult, model4_opt_oth` from `results_h1`.
- Title: `"Table S9: H1 RDD by Topic — FE, Optimal BW (Day Running Variable)"`
- File: `table_s09_fe_topic_opt_days`

**S9 (Prob), S9 (Cont), S9 (Drop):** From respective result objects.

### Task 8.2: Table S10 — H2 by-topic FE opt BW (all 4 variants)
Current Table 2B code. File pattern: `table_s10_fe_topic_opt_*`

### Task 8.3: Table S11 — H3a by-topic FE opt BW (all 4 variants)
Current Table 3B code. Include bootstrap vcov. File pattern: `table_s11_fe_topic_opt_*`

### Task 8.4: Table S12 — H3b by-topic FE opt BW (all 4 variants)
Current Table 4B code. Include bootstrap vcov. File pattern: `table_s12_fe_topic_opt_*`

---

## Phase 9: Supplementary Tables S13–S15 — By-Topic FE Full Data

H1 does not have full-data by-topic tables. Only H2, H3a, H3b.

### Task 9.1: Table S13 — H2 by-topic FE full data (all 4 variants)
Current Table 2D code. File pattern: `table_s13_fe_topic_full_*`

### Task 9.2: Table S14 — H3a by-topic FE full data (all 4 variants)
Current Table 3D code. Include bootstrap vcov. File pattern: `table_s14_fe_topic_full_*`

### Task 9.3: Table S15 — H3b by-topic FE full data (all 4 variants)
Current Table 4D code. Include bootstrap vcov. File pattern: `table_s15_fe_topic_full_*`

---

## Phase 10: Supplementary Tables S16–S17 — Additional Robustness

### Task 10.1: Table S16 — H2 Full FE Robustness (all 4 variants)

Current Table 2-S structure: 2 columns (`model2b_full_fe, model3a_opt_full_fe`).

**S16 (Days):** From `results_h2`. File: `table_s16_h2_full_fe_robustness_days`
**S16 (Prob), S16 (Cont), S16 (Drop):** From respective objects.

### Task 10.2: Table S17 — H2 State vs. Independent RDDs, FE (all 4 variants)

Current Table 2L structure: 2 columns (`model2_state_rdd, model2_ind_rdd`). These are FE-based rdrobust models (the Z-score versions are in the main Table 2).

**S17 (Days):** From `results_h2`. File: `table_s17_h2_state_ind_rdd_days`
**S17 (Prob), S17 (Cont), S17 (Drop):** From respective objects — verify these models exist in variants; TODO if not.

---

## Phase 11: Supplementary Tables S18–S22 — Descriptive & Diagnostic

These are standalone tables with no data variants.

### Task 11.1: Table S18 — Country Classification
Current comparison table code. File: `table_s18_country_classification`

### Task 11.2: Table S19 — Alignment Classification
Current alignment table code. File: `table_s19_alignment_classification`

### Task 11.3: Table S20 — Ethnic Population Classification
Current ethnic table code. File: `table_s20_ethnic_classification`

### Task 11.4: Table S21 — Leave-One-Out Country Robustness
Current LOO table code. File: `table_s21_loo_robustness`

### Task 11.5: Table S22 — Placebo Test Summary
Current placebo summary code. File: `table_s22_placebo_summary`

---

## Phase 12: Cleanup and Validation

### Task 12.1: Remove old/orphaned table code
Delete any table code chunks that are no longer referenced under the new numbering. Every chunk in the file should correspond to a table in the numbering system above.

### Task 12.2: Update summary section
Replace the `summary` chunk with an updated listing that reflects the new numbering scheme. Group by main vs. supplementary and list all data variants.

### Task 12.3: Verify Rmd structure
Scan the file for:
- Matched code chunk open/close pairs
- No duplicate chunk names
- All `save_table()` calls use unique filenames
- Section headers follow the Rmd outline

### Task 12.4: Final review
Read through the entire file top to bottom. Flag any inconsistencies in formatting, notes, or model references.

---

## Rmd Section Structure (Final)

The reorganized file should follow this outline:

```
---
title / author / date / output YAML
---

# Overview
# Load Results
# Helper Functions for Bootstrap Standard Errors
# Table Output Helper (with updated SE_NOTE constants)
# Model Verification

# =============================================
# MAIN PAPER TABLES
# =============================================

## Table 1: H1 RDD (Day)
## Table 2: H2 Diff-in-Disc (Day)
## Table 3: H3a Alignment (Day)
## Table 4: H3b Ethnic (Day)

## Table 1 (Prob) / Table 2 (Prob) / Table 3 (Prob) / Table 4 (Prob)
## Table 1 (Cont) / Table 2 (Cont) / Table 3 (Cont) / Table 4 (Cont)
## Table 1 (Drop) / Table 2 (Drop) / Table 3 (Drop) / Table 4 (Drop)

# =============================================
# SUPPLEMENTARY TABLES
# =============================================

## --- S1–S4: FE-Based Main Results ---
### S1 (Days) / S1 (Prob) / S1 (Cont) / S1 (Drop)
### S2 ... / S3 ... / S4 ...

## --- S5–S8: By-Topic Z-Score ---
### S5–S8, each × 4 variants

## --- S9–S12: By-Topic FE Optimal BW ---
### S9–S12, each × 4 variants

## --- S13–S15: By-Topic FE Full Data ---
### S13–S15, each × 4 variants

## --- S16–S17: Additional Robustness ---
### S16–S17, each × 4 variants

## --- S18–S22: Descriptive & Diagnostic ---
### S18–S22 (standalone, no variants)

# =============================================
# Session Info
# =============================================
```
