# russia_sentiment_paper

Analysis of sentiment in news coverage related to Russia, examining the effect of the 2022 invasion on media sentiment across post-Soviet and neighboring states.

## Project Structure

```
russia_sentiment_paper/
├── data/
│   ├── raw/                 # Original article data
│   ├── processed/           # GPT-coded and cleaned data
│   └── intermediate/        # Pipeline intermediate files (.rds)
├── scripts/                 # R Markdown analysis pipeline
│   ├── 00_setup.R           # Shared packages and functions
│   ├── 01_data_loading.Rmd  # Load raw data
│   ├── 02_data_cleaning.Rmd # Clean and create variables
│   ├── 03_descriptive_analysis.Rmd
│   ├── 04_main_rdd_analysis.Rmd      # Hypothesis 1
│   ├── 05_diff_in_disc_analysis.Rmd  # Hypothesis 2
│   ├── 06_heterogeneity_analysis.Rmd # Robustness
│   ├── 07_publication_outputs.Rmd    # Final tables
│   ├── master.Rmd           # Run entire pipeline
│   └── README.md            # Scripts documentation
├── figures/                 # Generated plots and tables
├── output/                  # Papers, presentations, HTML reports
├── .gitignore
└── README.md
```

## Quick Start

### Run the Full Analysis Pipeline

```r
setwd("scripts")
rmarkdown::render("master.Rmd")
```

### Run Individual Steps

```r
source("scripts/00_setup.R")
rmarkdown::render("scripts/01_data_loading.Rmd")
rmarkdown::render("scripts/02_data_cleaning.Rmd")
# ... continue as needed
```

## Data Pipeline

```
data/raw/                          data/processed/
┌─────────────────────────┐        ┌──────────────────────────────────┐
│ total_combined_articles │───────>│ GPTcoded_final_rus_articles      │
│ additional_total_*      │  GPT   │ secondhalf_GPTcoded_*            │
│ combined_articles       │ coding │ coded_articles_final             │
└─────────────────────────┘        │ GPT_Russian_Agreement_*          │
                                   └──────────────────────────────────┘
                                                  │
                                                  ▼
                                        scripts/01-07 pipeline
                                                  │
                                                  ▼
                                          figures/ + output/
```

## Analysis Pipeline

| Step | Script | Description |
|------|--------|-------------|
| 0 | `00_setup.R` | Load packages, define functions and constants |
| 1 | `01_data_loading.Rmd` | Load raw GPT-coded article data |
| 2 | `02_data_cleaning.Rmd` | Clean data, create analysis variables |
| 3 | `03_descriptive_analysis.Rmd` | Summary statistics, distributions, EDA |
| 4 | `04_main_rdd_analysis.Rmd` | **H1**: Effect of invasion on sentiment (RDD) |
| 5 | `05_diff_in_disc_analysis.Rmd` | **H2**: State vs independent media (Diff-in-Disc) |
| 6 | `06_heterogeneity_analysis.Rmd` | Heterogeneity by alignment and ethnicity |
| 7 | `07_publication_outputs.Rmd` | Generate final tables and figures |

## Required R Packages

```r
install.packages("pacman")
pacman::p_load(
  tidyverse, data.table, lubridate, ggplot2, patchwork,
  gt, kableExtra, modelsummary, stargazer,
  fixest, lfe, rdrobust, estimatr, here
)
```

## Large Files (Not in Git)

The following files exceed GitHub's 100MB limit and are stored locally via Dropbox:

| File | Size | Location |
|------|------|----------|
| `GPTcoded_final_rus_articles.csv` | 793 MB | `data/processed/` |
| `total_combined_articles.csv` | 761 MB | `data/raw/` |

Contact the repository owner for access to these files.

## Outputs

### Tables
- `figures/table_1.html` - Main RDD results
- `figures/table_2.html` - Diff-in-disc results
- `figures/table_3.html` - Heterogeneity analysis

### Figures
- `figures/invasion_on_sentiment.png` - Main RDD visualization
- `figures/invasion_discs_graph.png` - Diff-in-disc visualization
- `figures/articles_per_day.png` - Time series of article counts

## License

Contact repository owner for usage terms.
