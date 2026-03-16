# Plan: Three Fixes Across 08a-08d

## Instructions for Claude Code

### Resumability

1. Create `08_fixes_progress.md` in the project root. Initialize with every task below as `- [ ]`.
2. Before each task, read `08_fixes_progress.md`. Skip any `- [x]` task.
3. After completing each task, mark it `- [x]` and save immediately.
4. If resuming after compaction/restart, read `08_fixes_progress.md` and jump to the first unchecked task.

### Overview

Three changes need to be made across all four publication output files (08a, 08b, 08c, 08d):

**Fix 1:** Add `override_interaction_stars` helper to `00_setup.R` and replace all manual `text_transform` loops with calls to it.

**Fix 2:** Move the full-data Z-score interaction model out of main Tables 2 and 4 into supplement tables S3 and S7 as a new first column.

**Fix 3:** Demote Table 5 (H3a by-topic Z-score) from main paper to supplement, renumber Table 6 → Table 5, and renumber all affected supplement tables.

**Do 08a first, validate, then apply identical changes to 08b, 08c, 08d.**

---

## Fix 1: Override Interaction Stars Helper

### Task 1.1: Add helper to 00_setup.R

Add this function to `00_setup.R` alongside the other publication helpers (`create_bootstrap_vcov`, `get_boot_stars`, etc.):

```r
override_interaction_stars <- function(tbl, boot_results, col_names, row_idx = 3) {
  for (i in seq_along(boot_results)) {
    boot_p <- boot_results[[i]]$p_val
    stars <- get_boot_stars(boot_p)
    make_fn <- function(s) {
      function(x) {
        val <- gsub("[+*]+$", "", x)
        paste0(val, s)
      }
    }
    tbl <- tbl %>%
      text_transform(
        locations = cells_body(columns = col_names[i], rows = row_idx),
        fn = make_fn(stars)
      )
  }
  tbl
}
```

### Task 1.2: Replace all text_transform loops in 08a

Search 08a for every instance of the manual `text_transform` loop pattern:

```r
for (i in seq_along(boot_results_...)) {
  boot_p <- boot_results_...[[i]]$p_val
  boot_stars <- get_boot_stars(boot_p)
  table_... <- table_... %>%
    text_transform(
      ...
    )
}
```

Replace each instance with a single call:

```r
table_X <- override_interaction_stars(table_X, boot_results_tX, boot_col_names_tX)
```

This applies to every table that uses Pattern B or Pattern B-fe — specifically any table with an interaction term that uses bootstrap p-values for stars. These include at minimum:
- Table 2 (H2 main)
- Table 3 (H2 by-topic, if it has bootstrap star override)
- Table 4 (H3a main)
- Table 5/6 (H3b, if it exists and has bootstrap star override)
- S3 (H2 FE core)
- S4 (H2 FE robustness)
- S5 (H2 by-topic FE)
- S7 (H3a FE core)
- S8 (H3a by-topic FE)
- Any table with the old `text_transform` loop

**Search exhaustively** — do not assume you know all locations. `grep` for `text_transform` and `get_boot_stars` to find every instance.

Also remove any diagnostic `cat()` statements that may have been left in from debugging.

### Task 1.3: Apply Fix 1 to 08b, 08c, 08d

Apply the same `text_transform` loop → `override_interaction_stars()` replacement in all three other files. The changes should be identical since the code structure is the same across files.

---

## Fix 2: Move Full-Data Z-Score Models to Supplements

### Task 2.1: Remove full-data model from Table 2 in 08a

**Current Table 2** has 8 columns (using H2 models). Remove the full-data Z-score interaction model. The column to remove is whichever one uses `results_h2$model2a_z` (the full-data, no bandwidth restriction model).

After removal, Table 2 should have 7 columns:

| Col | Model |
|-----|-------|
| (1)‡ | `model2_state_rdd_z` |
| (2)‡ | `model2_ind_rdd_z` |
| (3)† | `model2a_opt_z` |
| (4)† | `model2b_z` |
| (5)† | `model2d_z` |
| (6)† | `model3a_z` |
| (7)† | `matched_model_z` |

Update:
- The model list (remove the full-data entry)
- The `boot_keys` list (remove the corresponding key)
- The `boot_results` list
- The `vcov` list
- The `rows` tribble (one fewer column)
- The `boot_col_names` for the star override (adjust column name strings)
- The table notes (remove "Model N uses the full dataset" reference, renumber model descriptions)
- Column numbers in notes to match new layout

### Task 2.2: Add full-data Z-score model to S3 in 08a

S3 is the H2 FE interaction core supplementary table. Add `model2a_z` as a new **first column** (before the existing FE models). This means S3 goes from 8 to 9 columns.

For this new column:
- It uses Z-score DV (not FE), so the Source Z-Score row should show `X` and the Source FEs row should show `-`
- It needs bootstrap vcov: `create_bootstrap_vcov(results_h2$model2a_z, results_h2$bootstrap_se$model2a_z, "treatment:state_owned")`
- It needs bootstrap star override (included in the `override_interaction_stars` call)

Update the rows tribble, vcov list, boot_keys, boot_results, boot_col_names, notes, and title as needed.

### Task 2.3: Remove full-data model from Table 4 in 08a

**Current Table 4** has 7 columns (using H3a models). Remove whichever column uses `results_align$model5a_z` (the full-data model).

After removal, Table 4 should have 6 columns:

| Col | Model |
|-----|-------|
| (1)‡ | `model5a_csto_z` |
| (2)‡ | `model5a_neutral_z` |
| (3)† | `model5a_opt_z` |
| (4)† | `model5a_opt_non_mil_z` |
| (5)† | `model5a_opt_russian_z` |
| (6)† | `matched_model` |

Update all the same elements as in Task 2.1 (model list, boot_keys, vcov, rows, notes, etc.).

### Task 2.4: Add full-data Z-score model to S7 in 08a

S7 is the H3a FE interaction + robustness supplementary table. Add `model5a_z` as a new **first column**. S7 goes from 9 to 10 columns.

Same approach as Task 2.2 but with:
- `create_bootstrap_vcov(results_align$model5a_z, results_align$bootstrap_se$model5a_z, "treatment:csto")`
- Update rows, vcov, boot_keys, boot_results, boot_col_names, notes

### Task 2.5: Apply Fix 2 to 08b, 08c, 08d

Apply identical changes to Tables 2 and 4 and supplement tables S3 and S7 in all three other files. The model names are the same — only the results objects differ (e.g., `results_h2_prob` vs `results_h2` etc.), but since each file already loads its own results objects under the same variable names (`results_h2`, `results_align`), the code changes are identical.

---

## Fix 3: Demote Table 5, Renumber

### Task 3.1: Move Table 5 to supplement in 08a

The current Table 5 (H3a by-topic Z-score, 5 columns) needs to move from the main tables section to the supplementary section. 

Determine the correct supplement number. With the current numbering:
- S1: H1 FE robustness
- S2: H1 by-topic Z-score
- S3: H2 FE core (now 9 cols after Fix 2)
- S4: H2 FE robustness
- S5: H2 by-topic FE
- S6: H2 LOO
- S7: H3a FE core (now 10 cols after Fix 2)
- S8: H3a by-topic FE
- S9: H3a LOO
- S10: Placebo

The H3a by-topic Z-score should go with the other H3a supplements, between S7 and S8. Insert it as the new **S8**, and bump the old S8 → S9, old S9 → S10, old S10 → S11.

**New supplement numbering:**
- S1: H1 FE robustness
- S2: H1 by-topic Z-score
- S3: H2 FE core
- S4: H2 FE robustness
- S5: H2 by-topic FE
- S6: H2 LOO
- S7: H3a FE core
- **S8: H3a by-topic Z-score (demoted from Table 5)**
- S9: H3a by-topic FE (was S8)
- S10: H3a LOO (was S9)
- S11: Placebo (was S10)

### Task 3.2: Renumber Table 6 → Table 5 in 08a

The current Table 6 (H3b null result) becomes Table 5. Update:
- The section header
- The table title
- The `save_table()` filename (should become `table_05_main`)
- Any cross-references in notes

**New main table numbering:**
- Table 1: H1 RDD hybrid
- Table 2: H2 interaction Z-score (7 cols after Fix 2)
- Table 3: H2 by-topic Z-score
- Table 4: H3a interaction Z-score (6 cols after Fix 2)
- Table 5: H3b null result Z-score (was Table 6)

### Task 3.3: Update all supplement table titles and filenames in 08a

For every supplement table that was renumbered (S8 through S11), update:
- Section header
- Table title
- `save_table()` filename
- Any internal references

### Task 3.4: Update the summary section in 08a

Update the summary `cat()` block at the end of the file to reflect the new table numbering.

### Task 3.5: Apply Fix 3 to 08b, 08c, 08d

Apply identical renumbering changes to all three other files.

---

## Validation

### Task 4.1: Verify 08a

In 08a, check:
- No remaining manual `text_transform` loops (all replaced with `override_interaction_stars`)
- No remaining `cat(sprintf(` debug statements
- Table 2 has exactly 7 columns, no full-data model
- Table 4 has exactly 6 columns, no full-data model
- S3 has the full-data Z-score model as column 1
- S7 has the full-data Z-score model as column 1
- Old Table 5 is now S8 in the supplement section
- Old Table 6 is now Table 5
- S8 through S11 are correctly numbered
- All `save_table()` filenames are unique and correctly numbered
- No duplicate chunk names

### Task 4.2: Verify 08b, 08c, 08d

Same checks as 4.1 for each file. Additionally verify that the only differences between files are:
- YAML title
- `TABLE_SUBDIR` value
- `readRDS()` filenames
- Table title text (data variant description)
