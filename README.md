# russia_sentiment_paper

Analysis of sentiment in news coverage related to Russia.

## Project Structure

```
russia_sentiment_paper/
├── data/
│   ├── raw/                 # Original article data
│   └── processed/           # GPT-coded and cleaned data
├── scripts/                 # R Markdown analysis files
├── figures/                 # Generated plots and tables
├── output/                  # Papers and presentations
└── README.md
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
                                                  v
                                          scripts/analysis.Rmd
                                                  │
                                                  v
                                            figures/ + output/
```

## Scripts

| File | Description |
|------|-------------|
| `scripts/analysis.Rmd` | Main analysis: sentiment trends, regressions, visualizations |
| `scripts/article_combiner.Rmd` | Combines raw article data from multiple sources |
| `scripts/one_pager.qmd` | Summary document for presentations |

## Large Files (Not in Git)

The following files exceed GitHub's 100MB limit and are stored locally via Dropbox:

| File | Size | Location |
|------|------|----------|
| `GPTcoded_final_rus_articles.csv` | 793 MB | `data/processed/` |
| `total_combined_articles.csv` | 761 MB | `data/raw/` |

Contact the repository owner for access to these files.
