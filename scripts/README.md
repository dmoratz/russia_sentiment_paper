# Analysis Scripts

This folder contains the modular R Markdown analysis pipeline for the Russia sentiment paper.

## Quick Start

To run the entire analysis pipeline:

```r
# Open RStudio and set working directory to scripts/
setwd("scripts")

# Run the master script
rmarkdown::render("master.Rmd")
```

Or run individual scripts in order:

```r
source("00_setup.R")
rmarkdown::render("01_data_loading.Rmd")
rmarkdown::render("02_data_cleaning.Rmd")
# ... etc.
```

## Pipeline Overview

```
00_setup.R ─────────────────────────────────────────────────────────────────┐
     │                                                                       │
     ▼                                                                       │
01_data_loading.Rmd ──► 01_raw_data.rds                                      │
     │                                                                       │
     ▼                                                                       │
02_data_cleaning.Rmd ──► 02_cleaned_data.rds                                 │
     │                     02_data_non_ukraine.rds                           │
     │                     02_data_non_ukraine_ind.rds                       │
     │                                                                       │
     ├────────────────┬────────────────┬─────────────────┐                   │
     ▼                ▼                ▼                 │                   │
03_descriptive   04_main_rdd     05_diff_in_disc        │                   │
     │                │                │                 │                   │
     │                └────────┬───────┘                 │                   │
     │                         ▼                         │                   │
     │               06_heterogeneity_analysis           │                   │
     │                         │                         │                   │
     └─────────────────────────┴─────────────────────────┘                   │
                               │                                             │
                               ▼                                             │
                    07_publication_outputs ◄─────────────────────────────────┘
```

## File Descriptions

| File | Purpose | Inputs | Outputs |
|------|---------|--------|---------|
| `00_setup.R` | Shared packages, functions, constants | - | - |
| `01_data_loading.Rmd` | Load raw GPT-coded data | CSV files | `01_raw_data.rds` |
| `02_data_cleaning.Rmd` | Clean data, create variables | `01_raw_data.rds` | `02_*.rds` files |
| `03_descriptive_analysis.Rmd` | Summary stats, EDA, time series | `02_*.rds` | Tables, plots |
| `04_main_rdd_analysis.Rmd` | Hypothesis 1: RDD analysis | `02_*.rds` | `04_h1_results.rds` |
| `05_diff_in_disc_analysis.Rmd` | Hypothesis 2: Diff-in-disc | `02_*.rds` | `05_h2_results.rds` |
| `06_heterogeneity_analysis.Rmd` | Alignment & ethnic effects | `02_*.rds` | `06_het_results.rds` |
| `07_publication_outputs.Rmd` | Final tables and figures | `04/05/06_*.rds` | Publication outputs |
| `master.Rmd` | Run entire pipeline | All above | All outputs |
| `analysis.Rmd` | Original monolithic script (archived) | - | - |

## Required Packages

The following R packages are required (automatically loaded via `00_setup.R`):

### Data Manipulation
- tidyverse, dplyr, tidyr, purrr
- data.table, lubridate, stringr

### Visualization
- ggplot2, patchwork, cowplot
- scales, ggpubr

### Tables
- gt, knitr, kableExtra
- modelsummary, stargazer

### Statistical Analysis
- estimatr, fixest, lfe
- plm, rdrobust, sandwich, lmtest

### Other
- here, broom, pacman

Install all packages at once:

```r
install.packages("pacman")
pacman::p_load(
  tidyverse, data.table, lubridate, stringr,
  ggplot2, patchwork, cowplot, scales, ggpubr,
  gt, knitr, kableExtra, modelsummary, stargazer,
  estimatr, fixest, lfe, plm, rdrobust, sandwich, lmtest,
  here, broom
)
```

## Output Locations

| Output Type | Location |
|-------------|----------|
| Intermediate data | `data/intermediate/*.rds` |
| Figures (PNG) | `figures/*.png` |
| Tables (HTML) | `figures/*.html` |
| HTML reports | `output/*.html` |

### Pre-Trend Robustness Outputs (reviewer response)

Added to the probabilistic-time pipeline to address the concern that sentiment toward Russia
may have shifted negatively during the pre-invasion buildup in aligned state media:

| Output | Built in | Location |
|--------|----------|----------|
| `pretrend_by_country_aligned.png` (small-multiples pre-trend figure: state media, one panel per Russia-aligned country; Dec 7 & Feb 24 markers; pre-invasion linear fit; window from 2021-06-01) | `06C_russian_alignment_analysis_prob.Rmd` (chunk `pretrend-by-country-aligned-prob`) | `figures/heterogeneity/prob/` |
| `pretrend_by_country_aligned_dec.png` (same figure, later start 2021-12-01, window-robustness) | `06C` (chunk `pretrend-by-country-aligned-dec-prob`) | `figures/heterogeneity/prob/` |
| Per-country pre-invasion slope printout | `06C` (chunk `pretrend-slopes-aligned-prob`) | console |
| `placebo_aligned_models` (named list; one Dec 7, 2021 placebo RDD per aligned country; state-owned non-military media; `rdrobust`, MSE-optimal bandwidth, z-scored outcome, default HC SEs — no clustering, since each country has 2-3 sources) | `06C` (chunk `placebo-dec-aligned-prob`) → serialized in `06_alignment_results_prob.rds` | `data/intermediate/` |
| `table_s13_placebo_aligned` (appendix table; four aligned countries side-by-side as columns) | `08a_publication_outputs.Rmd` (chunk `table-s13`) | `figures/tables/prob/` |

## Key Functions (from 00_setup.R)

### `clean_datetime_col(date_col)`
Converts date strings to POSIXct, handling both full datetime and date-only formats.

### `validate_data(data, stage)`
Prints a validation summary showing row count, column count, and missing values.

### `print_session_info()`
Prints R version and key package versions for reproducibility.

### `compute_effect_size(coefficient, data)`
Computes effect size in standard deviation units.

## Constants (from 00_setup.R)

```r
# Country groupings
CSTO_COUNTRIES <- c("Armenia", "Azerbaijan", "Belarus", "Kazakhstan")
NATO_COUNTRIES <- c("Albania", "Ukraine", "Turkey", "Hungary")
NEUTRAL_COUNTRIES <- c("Georgia", "Moldova", "Kosovo", "Serbia")

# Ethnic Russian population
HIGH_RUSSIAN_POP <- c("Moldova", "Belarus", "Kazakhstan", "Georgia")
LOW_RUSSIAN_POP <- c("Azerbaijan", "Armenia", "Kosovo", "Serbia")
```

## Troubleshooting

### Missing packages
```r
# Install missing packages
pacman::p_load(package_name)
```

### Path issues
Ensure working directory is set to `scripts/`:
```r
setwd("path/to/russia_sentiment_paper/scripts")
```

### Memory issues with large datasets
The intermediate `.rds` files use R's native serialization which is memory-efficient. If you encounter memory issues:
1. Restart R session
2. Run scripts individually rather than via `master.Rmd`
3. Consider increasing R's memory limit

## Reproducibility

Each script includes:
- Session info at the end (`print_session_info()`)
- Set seed for random operations (`set.seed(3184)`)
- Clear documentation of inputs and outputs

To fully reproduce the analysis:
1. Clone the repository
2. Obtain the large data files (see main README)
3. Run `master.Rmd`
