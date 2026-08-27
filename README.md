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
│   ├── 03A_descriptive_analysis.Rmd, 03B_coding_analysis.Rmd
│   ├── 04{a,b,d}_main_rdd_analysis_*.Rmd        # H1 (prob/days/drop)
│   ├── 05{a,b,d}_diff_in_disc_analysis_*.Rmd    # H2 (prob/days/drop)
│   ├── 06{a,b,d}_russian_alignment_analysis_*.Rmd # H3a (prob/days/drop)
│   ├── 07{a,b,d}_ethnic_russian_analysis_*.Rmd  # H3b (prob/days/drop)
│   ├── 08_bandwidth_sensitivity.Rmd
│   ├── 09{a,b,d}_publication_outputs_*.Rmd      # Final tables per variant
│   ├── archive/             # Retired continuous-time (c) scripts + lifted diagnostics
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

Each hypothesis is run in three time-treatment **variants**, suffixed `a`/`b`/`d`:
`a` = **probabilistic** time assignment (primary), `b` = **day** running variable,
`d` = **drop** no-time articles. The continuous-time variant (`c`) has been retired to
`scripts/archive/`. Within each family the variants run in the order prob → days → drop.

| Step | Script | Description |
|------|--------|-------------|
| 0 | `00_setup.R` | Load packages, define functions and constants |
| 1 | `01_data_loading.Rmd` | Load raw GPT-coded article data |
| 2 | `02_data_cleaning.Rmd` | Clean data, create analysis variables |
| 3A/3B | `03A_descriptive_analysis.Rmd`, `03B_coding_analysis.Rmd` | Summary stats, EDA, coding reliability |
| 4 | `04{a,b,d}_main_rdd_analysis_*.Rmd` | **H1**: Effect of invasion on sentiment (RDD) |
| 5 | `05{a,b,d}_diff_in_disc_analysis_*.Rmd` | **H2**: State vs independent media (Diff-in-Disc) |
| 6 | `06{a,b,d}_russian_alignment_analysis_*.Rmd` | **H3a**: CSTO alignment (incl. pre-trend + Dec-7 placebo) |
| 7 | `07{a,b,d}_ethnic_russian_analysis_*.Rmd` | **H3b**: Ethnic Russian population effects |
| 8 | `08_bandwidth_sensitivity.Rmd` | Bandwidth sensitivity analysis |
| 9 | `09{a,b,d}_publication_outputs_*.Rmd` | Generate final tables (`.tex`/`.html`) per variant |

Run the whole pipeline via `scripts/master.Rmd`.

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

Publication tables are written per variant to `figures/tables/{prob,days,drop}/`, in both
`.tex` and `.html`. The probabilistic variant is primary.

- `figures/tables/prob/table_01_main.*` - H1 RDD, effect of the invasion on sentiment
- `figures/tables/prob/table_02_main.*` - H2 diff-in-disc, state ownership interaction
- `figures/tables/prob/table_03_main.*` - H2 diff-in-disc by topic
- `figures/tables/prob/table_04_main.*` - H3a alignment interaction
- `figures/tables/prob/table_05_main.*` - H3b ethnic Russian population (null result)
- `figures/tables/prob/table_s12_placebo.tex` - Placebo test summary (Dec 7, 2021 false cutoff)
- `figures/tables/prob/table_s13_placebo_aligned.tex` - Placebo RDD for state-owned media in
  the Russia-aligned group, run separately per country (columns), Dec 7, 2021 cutoff

### Figures

Figures are written to per-variant subdirectories (`days`, `prob`, `drop`) under the
relevant family folder, so the variants do not overwrite one another. The three
discontinuity plots used in the paper come from the **day** variant, whose coarser
grouping keeps the scatter legible:

- `figures/rdd/days/invasion_on_sentiment_non_mil.png` - Main RDD visualization
- `figures/diff_in_disc/days/invasion_discs_non_mil.png` - Diff-in-disc visualization
- `figures/heterogeneity/days/state_align_discs.png` - Alignment diff-in-disc visualization
- `figures/descriptive/articles_per_day.png` - Time series of article counts
- `figures/heterogeneity/prob/pretrend_by_country_aligned.png` - Pre-invasion sentiment
  trend in state media, one panel per Russia-aligned country, marking the Dec 7, 2021
  warning date and the Feb 24, 2022 invasion cutoff with a linear pre-invasion fit
  (window starts 2021-06-01)
- `figures/heterogeneity/prob/pretrend_by_country_aligned_dec.png` - Same figure with a
  later start date (2021-12-01), confirming the trend is not an artifact of a long window

### Pre-Trend Robustness (added for reviewer response)

Two objects address the concern that sentiment toward Russia may have turned negative during
the pre-invasion troop buildup, especially in state-owned media of Russia-aligned countries
(Armenia, Azerbaijan, Belarus, Kazakhstan):

- **Pre-trend figures** (`pretrend_by_country_aligned.png` and the later-start replica
  `pretrend_by_country_aligned_dec.png`, built in `06a_russian_alignment_analysis_prob.Rmd`):
  daily mean sentiment for state-owned sources by aligned country, with a linear fit on the
  pre-invasion window only. The two versions differ only in start date (2021-06-01 vs
  2021-12-01) to show the slope is not a long-window artifact.
- **Per-country aligned placebos** (`table_s13_placebo_aligned`, models built in `06a`,
  table in `09a_publication_outputs_prob.Rmd`): a Dec 7, 2021 placebo RDD (`rdrobust`, MSE-optimal
  bandwidth, source-level z-scored outcome, default HC SEs) run separately for each aligned
  country's state-owned, non-military media, reported side-by-side.

## License

Contact repository owner for usage terms.
