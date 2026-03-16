# Plan: 09_bandwidth_sensitivity.Rmd

## Instructions for Claude Code

### Resumability

1. Create `09_bw_sensitivity_progress.md` in the project root. Initialize with every task below as `- [ ]`.
2. Before each task, read `09_bw_sensitivity_progress.md`. Skip any `- [x]` task.
3. After completing each task, mark it `- [x]` and save immediately.
4. If resuming after compaction/restart, read `09_bw_sensitivity_progress.md` and jump to the first unchecked task.

### Reference Files

- `06C_russian_alignment_analysis_prob.Rmd` — for how Z-score computation, data subsetting, and bandwidth selection work for H3a
- `07C_ethnic_russian_analysis_prob.Rmd` — for H3b data prep (after it's been updated)
- `05C_h2_analysis_prob.Rmd` (or equivalent) — for H2 data prep
- `04C_h1_analysis_prob.Rmd` (or equivalent) — for H1 data prep

### Overview

Create `09_bandwidth_sensitivity.Rmd` that produces 4 bandwidth sensitivity figures (one per hypothesis) for 2 data variants (probabilistic as primary, days as robustness). Each figure shows how the main coefficient estimate + 95% CI varies across a grid of 10 bandwidths from 50% to 200% of the optimal.

All figures use non-military topics (except H1 which uses all topics) and Z-score DVs, matching the main table specifications.

### Output

- 4 figures for probabilistic variant, saved to `FIGURES_TABLES/prob/`
- 4 figures for days variant, saved to `FIGURES_TABLES/days/`
- Filenames: `bw_sensitivity_h1.png`, `bw_sensitivity_h2.png`, `bw_sensitivity_h3a.png`, `bw_sensitivity_h3b.png`

---

## Phase 1: File Setup

### Task 1.1: Create file header and load data

```yaml
---
title: "09 - Bandwidth Sensitivity Analysis"
author: "Donald Moratz"
date: "`r format(Sys.time(), '%B %d, %Y')`"
output:
  html_document:
    toc: true
    toc_float: true
    code_folding: show
---
```

Source `00_setup.R`. Load the cleaned data:

```r
source("00_setup.R")

data <- readRDS(file.path(DATA_INTERMEDIATE, "02_cleaned_data.rds"))
data_non_ukraine <- readRDS(file.path(DATA_INTERMEDIATE, "02_data_non_ukraine.rds"))

data <- data %>% mutate(across(c(topic_clean, country, source_domain), as.factor))
data_non_ukraine <- data_non_ukraine %>% mutate(across(c(topic_clean, country, source_domain), as.factor))
```

### Task 1.2: Create bandwidth sensitivity helper function

```r
# Run a single model at a given bandwidth and extract coefficient + CI
# For feols interaction models
bw_sensitivity_feols <- function(data, running_var, bw, formula, coef_name) {
  d <- data %>% filter(abs(.data[[running_var]]) < bw)
  
  # Skip if too few observations or clusters
  n_clusters <- length(unique(d$source_domain))
  if (nrow(d) < 50 || n_clusters < 3) {
    return(tibble(bandwidth = bw, estimate = NA, se = NA, 
                  ci_lower = NA, ci_upper = NA, n_obs = nrow(d), n_clusters = n_clusters))
  }
  
  m <- tryCatch(
    feols(as.formula(formula), cluster = ~source_domain, data = d),
    error = function(e) NULL
  )
  
  if (is.null(m) || !(coef_name %in% names(coef(m)))) {
    return(tibble(bandwidth = bw, estimate = NA, se = NA, 
                  ci_lower = NA, ci_upper = NA, n_obs = nrow(d), n_clusters = n_clusters))
  }
  
  coef_val <- coef(m)[coef_name]
  se_val <- se(m)[coef_name]
  
  tibble(
    bandwidth = bw,
    estimate = coef_val,
    se = se_val,
    ci_lower = coef_val - 1.96 * se_val,
    ci_upper = coef_val + 1.96 * se_val,
    n_obs = nrow(d),
    n_clusters = n_clusters
  )
}

# For rdrobust models (H1)
bw_sensitivity_rdrobust <- function(y, x, cluster, bw, covs = NULL) {
  m <- tryCatch(
    rdrobust(y = y, x = x, h = bw, cluster = cluster, covs = covs),
    error = function(e) NULL
  )
  
  if (is.null(m)) {
    return(tibble(bandwidth = bw, estimate = NA, se = NA, ci_lower = NA, ci_upper = NA))
  }
  
  tibble(
    bandwidth = bw,
    estimate = m$coef[1],
    se = m$se[1],
    ci_lower = m$ci[1, 1],
    ci_upper = m$ci[1, 2]
  )
}

# Plotting function
plot_bw_sensitivity <- function(results, optimal_bw, title, subtitle = NULL) {
  results %>%
    filter(!is.na(estimate)) %>%
    ggplot(aes(x = bandwidth, y = estimate)) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "steelblue", size = 2) +
    geom_vline(xintercept = optimal_bw, linetype = "dashed", color = "red", alpha = 0.7) +
    geom_hline(yintercept = 0, linetype = "solid", color = "grey50", alpha = 0.5) +
    annotate("text", x = optimal_bw, y = Inf, label = "Optimal BW", 
             vjust = 2, hjust = -0.1, color = "red", size = 3) +
    theme_classic() +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Bandwidth (days)",
      y = "Coefficient Estimate"
    )
}
```

---

## Phase 2: H1 Bandwidth Sensitivity

### Task 2.1: Prepare H1 data and run sensitivity (Probabilistic)

Follow the data preparation from the 04 analysis script (probabilistic variant). H1 uses all topics (not non-mil).

```r
# Prepare data the same way as 04C
# [Check 04C for exact data prep — filter, Z-score computation, running variable conversion]

# Get optimal bandwidth from saved results, or recompute
results_h1_prob <- readRDS(file.path(DATA_INTERMEDIATE, "04_h1_results_prob.rds"))
optimal_bw_h1 <- results_h1_prob$optimal_bandwidth

# Generate grid
bw_grid_h1 <- seq(0.5 * optimal_bw_h1, 2 * optimal_bw_h1, length.out = 10)

# Run rdrobust at each bandwidth
# Need: y (sentiment_z or sentiment_clean depending on H1 spec), x (running var), cluster, covs
results_bw_h1 <- map_df(bw_grid_h1, function(h) {
  bw_sensitivity_rdrobust(y = h1_data$sentiment_z, x = h1_data$running_var, 
                          cluster = h1_data$source_domain, bw = h, covs = covs_matrix)
})
```

**IMPORTANT:** Check the 04 analysis script to determine:
- What DV does the main H1 Z-score model use? (`sentiment_z` computed how?)
- What running variable? (probably `running_probabilistic / 86400`)
- What covariates in rdrobust? (likely `model.matrix(~ topic_clean + source_domain - 1)` or similar)
- What data subset? (all data or non-Ukraine?)

### Task 2.2: Plot and save H1 (Probabilistic)

```r
p_h1 <- plot_bw_sensitivity(
  results_bw_h1, optimal_bw_h1,
  title = "H1: Bandwidth Sensitivity — Effect of Invasion on Sentiment",
  subtitle = "Probabilistic Time Assignment"
)

p_h1
ggsave(file.path(FIGURES_TABLES, "prob", "bw_sensitivity_h1.png"), p_h1, width = 8, height = 5)
```

---

## Phase 3: H2 Bandwidth Sensitivity

### Task 3.1: Prepare H2 data and run sensitivity (Probabilistic)

Follow the data preparation from the 05 analysis script. H2 uses non-military topics, Z-score DV.

```r
# Prepare data — filter to non-mil, compute Z-score, convert running variable
# [Check 05C for exact data prep]

# Get optimal bandwidth
results_h2_prob <- readRDS(file.path(DATA_INTERMEDIATE, "05_h2_results_prob.rds"))
# The optimal BW for the non-mil Z-score model — check what key this is stored under

bw_grid_h2 <- seq(0.5 * optimal_bw_h2, 2 * optimal_bw_h2, length.out = 10)

results_bw_h2 <- map_df(bw_grid_h2, function(h) {
  bw_sensitivity_feols(
    data = h2_data_non_mil,
    running_var = "running_probabilistic",  # or whatever the column is called
    bw = h,
    formula = "sentiment_z ~ running_probabilistic * treatment * state_owned | topic_clean",
    coef_name = "treatment:state_owned"
  )
})
```

### Task 3.2: Plot and save H2 (Probabilistic)

```r
p_h2 <- plot_bw_sensitivity(
  results_bw_h2, optimal_bw_h2,
  title = "H2: Bandwidth Sensitivity — State vs. Independent Media",
  subtitle = "Non-Military Topics, Probabilistic Time"
)

p_h2
ggsave(file.path(FIGURES_TABLES, "prob", "bw_sensitivity_h2.png"), p_h2, width = 8, height = 5)
```

---

## Phase 4: H3a Bandwidth Sensitivity

### Task 4.1: Prepare H3a data and run sensitivity (Probabilistic)

Follow 06C data preparation. Non-mil, Z-score, state-owned media, non-NATO countries.

```r
# Prepare data following 06C pattern
# Filter: nato == 0, state_owned == 1, non-military
# Z-score: group_by(source_domain), compute sentiment_z
# Running variable: running_probabilistic / 86400

# Get optimal bandwidth for non-mil Z-score model
results_align_prob <- readRDS(file.path(DATA_INTERMEDIATE, "06_alignment_results_prob.rds"))
# Check what key stores the non-mil Z-score bandwidth

bw_grid_h3a <- seq(0.5 * optimal_bw_h3a, 2 * optimal_bw_h3a, length.out = 10)

results_bw_h3a <- map_df(bw_grid_h3a, function(h) {
  bw_sensitivity_feols(
    data = h3a_data_non_mil,
    running_var = "running_probabilistic",
    bw = h,
    formula = "sentiment_z ~ running_probabilistic * treatment * csto | topic_clean",
    coef_name = "treatment:csto"
  )
})
```

### Task 4.2: Plot and save H3a (Probabilistic)

```r
p_h3a <- plot_bw_sensitivity(
  results_bw_h3a, optimal_bw_h3a,
  title = "H3a: Bandwidth Sensitivity — CSTO vs. Neutral Alignment",
  subtitle = "Non-Military Topics, State Media, Probabilistic Time"
)

p_h3a
ggsave(file.path(FIGURES_TABLES, "prob", "bw_sensitivity_h3a.png"), p_h3a, width = 8, height = 5)
```

---

## Phase 5: H3b Bandwidth Sensitivity

### Task 5.1: Prepare H3b data and run sensitivity (Probabilistic)

Follow 07C data preparation (updated version). Non-mil, Z-score, state-owned, non-NATO.

```r
# Get optimal bandwidth
results_ethnic_prob <- readRDS(file.path(DATA_INTERMEDIATE, "07_ethnic_results_prob.rds"))
optimal_bw_h3b <- results_ethnic_prob$optimal_bw_ethnic_non_mil_z

bw_grid_h3b <- seq(0.5 * optimal_bw_h3b, 2 * optimal_bw_h3b, length.out = 10)

results_bw_h3b <- map_df(bw_grid_h3b, function(h) {
  bw_sensitivity_feols(
    data = h3b_data_non_mil,
    running_var = "running_probabilistic",
    bw = h,
    formula = "sentiment_z ~ running_probabilistic * treatment * high_russia | topic_clean",
    coef_name = "treatment:high_russia"
  )
})
```

### Task 5.2: Plot and save H3b (Probabilistic)

```r
p_h3b <- plot_bw_sensitivity(
  results_bw_h3b, optimal_bw_h3b,
  title = "H3b: Bandwidth Sensitivity — Ethnic Russian Population",
  subtitle = "Non-Military Topics, State Media, Probabilistic Time"
)

p_h3b
ggsave(file.path(FIGURES_TABLES, "prob", "bw_sensitivity_h3b.png"), p_h3b, width = 8, height = 5)
```

---

## Phase 6: Days Variant (Robustness)

### Task 6.1: Repeat Phases 2-5 for days variant

Load the days-variant data and results:
- `04_h1_results.rds`
- `05_h2_results.rds`
- `06_alignment_results.rds`
- `07_ethnic_results.rds`

Follow the same process but:
- Use the day running variable (check each analysis script for the correct variable name)
- Save figures to `FIGURES_TABLES/days/`
- Update subtitles to say "Day Running Variable"

**IMPORTANT:** The data preparation (filtering, Z-score computation) must match how each analysis script prepares data for its day variant. Check the 04/05/06/07 scripts (not the C variants) for the correct running variable name and any differences in data prep.

---

## Phase 7: Combined Figure (Optional)

### Task 7.1: Create a 2x2 combined figure

If useful for the paper, create a combined figure with all 4 hypotheses:

```r
library(patchwork)

combined <- (p_h1 + p_h2) / (p_h3a + p_h3b) +
  plot_annotation(title = "Bandwidth Sensitivity Analysis")

ggsave(file.path(FIGURES_TABLES, "prob", "bw_sensitivity_combined.png"), 
       combined, width = 14, height = 10)
```

---

## Phase 8: Update master.Rmd

### Task 8.1: Add 09 to master script

Add `09_bandwidth_sensitivity.Rmd` to `master.Rmd` after the 08 entries.
