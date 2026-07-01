# Plan: Pre-trend figure + Dec-7 placebo RDD for the Russia-aligned group

**Author:** Claude (for Donald)
**Date:** 2026-07-01
**Reviewer concern (Erik):** Sentiment toward Russia may have turned negative *before*
the Feb 24, 2022 invasion — during the troop buildup — especially in state-owned media in
Russia-aligned countries. If such a pre-trend exists, it threatens the RDD/RDID
discontinuity interpretation.

**Goal:** Produce two new empirical objects that speak directly to that concern, in the
existing house style, **without editing `main.tex` or any appendix `.tex`**. Deliverables:
a figure (Task A), an appendix table (Task B), and a printed numeric summary.

---

## 0. Orientation — what I found in the repo

Key facts that constrain the design (so the new code reuses, not reinvents, the pipeline):

- **Data / variables** (`scripts/02_data_cleaning.Rmd`, `00_setup.R`):
  - Outcome `sentiment_clean` ∈ {−1 (Negative), 0 (Neutral), 1 (Positive)} toward Russia.
  - `sentiment_z` = per-`source_domain` z-score of `sentiment_clean` (created inside the
    analysis chunks, group-by source, in 06C).
  - `date_publish` is a calendar `Date`; `date_publish_probabilistic` is the KDE-imputed
    POSIXct timestamp.
  - `running` = days from 2022-02-24; `running_probabilistic` = seconds from
    2022-02-24 00:00 (divided by 86400 → days inside analysis chunks).
  - `state_owned` = `source_domain %in% STATE_OWNED_SOURCES` (21 domains in `00_setup.R`).
  - `csto` = `country %in% CSTO_COUNTRIES`; `CSTO_COUNTRIES = {Armenia, Azerbaijan,
    Belarus, Kazakhstan}` — **exactly the Russia-aligned group in the task** (Azerbaijan
    included despite non-CSTO status; Ukraine excluded via the `nato==0` / non-Ukraine data).
  - `nato` flags NATO group (incl. Ukraine); alignment analyses start from `filter(nato == 0)`.

- **Existing sentiment figure style** (`04C`, chunk `rdd-plot-prob`, and the alignment
  figure `state_align_discs_prob` in `06C`): `ggplot` + `theme_classic()`; points are
  `group_by(running_probabilistic) %>% summarize(mean sentiment, num_obs)` sized by
  `num_obs` at `alpha = 0.2`; `geom_smooth(method = "lm")`; **the Feb-24 cutoff is
  `geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7)`**; colors from
  `COLORS_*` in `00_setup.R`; saved via `ggsave(width = 10, height = 7)`.

- **Existing placebo machinery:**
  - Main H1 placebo (`04C`, chunk `placebo-dec-prob`): **`rdrobust`** on `data_non_ukraine`,
    pre-invasion (`date_publish < "2022-02-19"`), non-military, cutoff **2021-12-07**,
    `covs = model.matrix(~ country + source_domain + topic_clean - 1)`,
    `cluster = source_domain`. rdrobust auto-selects the MSE-optimal ("mserd") bandwidth.
    A z-score twin (`model_placebo_z`) also exists. Saved into `04_h1_results_prob.rds`.
  - Group placebo (`06C`, chunk `placebo-dec-nonmil-prob`): a **diff-in-disc**
    `feols(sentiment_z ~ running_probabilistic * treatment * csto | topic_clean,
    cluster = ~source_domain)` at the same cutoff, with WCR bootstrap on `treatment:csto`
    via `run_wild_bootstrap()`. Saved as `model_placebo_nonmil` in `06_alignment_results_prob.rds`.
  - The single-group CSTO state-media RDDs already in `06C` (`model5a_csto`,
    `model5a_csto_z`) use **`rdrobust`** with `cluster = source_domain` — so a single-group
    `rdrobust` placebo restricted to CSTO state media is fully consistent with existing code.

- **Table style** (`08a`, chunk `table-s12`): `results_*` objects are read from the
  `*_results_prob.rds` files; the placebo summary is a `tibble` → `gt()` with columns
  Model / Estimate(+stars) / Std. Error / p-value / Bandwidth / N, `tab_header` +
  `tab_footnote`, saved with `save_table(tbl, name, "prob")` (writes `.tex` **and** `.html`
  to `figures/tables/prob/`), then post-processed by `fix_gt_caption()`.

- **Figure output folders:** alignment/heterogeneity figures live in
  `figures/heterogeneity/prob/` (`FIGURES_HETEROGENEITY_PROB`), e.g.
  `state_align_discs_prob.png`, `ethnic_discs_prob.png`.

- **Environment note:** the pipeline uses `here::here()` paths, `set.seed(3184)`,
  `source("00_setup.R")` at the top of each script, and `options(digits = 10)` in 06C.

---

## Task A — Pre-trend small-multiples figure (main text)

**What it shows:** one panel per Russia-aligned country (Armenia, Azerbaijan, Belarus,
Kazakhstan), **state-owned media only**, mean sentiment toward Russia over time, with the
Feb-24 cutoff and the Dec-7 warning date marked, and a fit on the **pre-invasion window
only** so a reader can judge whether sentiment was already sliding before the cutoff.

**Where the code goes:** new chunk in `06C_russian_alignment_analysis_prob.Rmd` (alignment
script), after the state-media alignment visualizations. **Output:**
`figures/heterogeneity/prob/pretrend_by_country_aligned.png`.

**Data build (mirrors existing filters):**
```r
data_pretrend <- data %>%                       # 02_cleaned_data.rds, already loaded in 06C
  filter(country %in% CSTO_COUNTRIES,           # Russia-aligned group; Ukraine excluded
         state_owned == 1)                       # state-owned only
# daily mean by country (same outcome + daily aggregation as existing sentiment figures)
agg_pretrend <- data_pretrend %>%
  group_by(country, date_publish) %>%
  summarize(sentiment_mean = mean(sentiment_clean, na.rm = TRUE),
            num_obs = n(), .groups = "drop")
```

**Plot (house style):**
- `ggplot(agg_pretrend, aes(date_publish, sentiment_mean))`
- `geom_point(aes(size = num_obs), alpha = 0.2)` — same point treatment as existing figures.
- **Feb-24 marker (standard dashed):** `geom_vline(xintercept = as.Date("2022-02-24"),
  linetype = "dashed", alpha = 0.7)`.
- **Dec-7 marker (second marker):** `geom_vline(xintercept = as.Date("2021-12-07"),
  linetype = "dotted")` (distinct style so the two dates are visually separable).
- **Pre-invasion fit only:** `geom_smooth(data = filter(agg_pretrend,
  date_publish < as.Date("2022-02-24")), method = "lm")` (and/or `method = "loess"` — see
  Q4). The fit is deliberately restricted to the pre-cutoff window.
- `facet_wrap(~ country, scales = "free_y")` → small multiples, one panel per country.
- `theme_classic()`, `labs(title = ..., subtitle = "State-owned media, Russia-aligned
  countries", x = "Publication date", y = "Mean sentiment toward Russia")`.
- `ggsave(width = 10, height = 7)` to `FIGURES_HETEROGENEITY_PROB`.

**Reported numbers (Task A):** the **pre-invasion linear slope** (coefficient on date,
per day, and rescaled per 30 days for readability) with SE and p-value, **per country** —
fit on state-owned pre-invasion daily means. This is the direct quantitative answer to
"was sentiment already sliding before Feb 24?"

**Open design choices → see Questions Q1 (x-axis/window) and Q4 (fit type).**

---

## Task B — Dec-7 placebo RDD for the allied group (appendix)

**What it is:** re-run the placebo-cutoff RDD, but restrict to **state-owned media in the
Russia-aligned (CSTO) group**, non-military, with the cutoff set to **Dec 7, 2021** (the US
public-warning date). This asks: is there a spurious "discontinuity" at the buildup-warning
date within exactly the media the reviewer is worried about?

**Where the code goes:** new chunk in `06C_russian_alignment_analysis_prob.Rmd`, next to the
existing `placebo-dec-nonmil-prob` chunk; the fitted model(s) added to `results_het_prob`
so they serialize into `06_alignment_results_prob.rds`. Table assembly + `.tex` in
`08a_publication_outputs.Rmd`.

**Estimation (mirrors the main H1 placebo exactly — the primary spec):**
```r
data_dec_csto <- data %>%
  filter(country %in% CSTO_COUNTRIES, state_owned == 1,
         topic_clean != "Military",
         date_publish < "2022-02-19") %>%           # same pre-invasion restriction as H1 placebo
  mutate(
    running_probabilistic = as.numeric(difftime(
      date_publish_probabilistic, as.POSIXct("2021-12-07 00:00:00", tz = "UTC"),
      units = "secs")) / 86400,
    treatment = ifelse(date_publish_probabilistic <
                       as.POSIXct("2021-12-07 00:00:00", tz = "UTC"), 0, 1))

covs_dec_csto <- model.matrix(~ country + topic_clean - 1, data = data_dec_csto)
model_placebo_aligned <- rdrobust(
  y = data_dec_csto$sentiment_clean,
  x = data_dec_csto$running_probabilistic,
  covs = covs_dec_csto,
  cluster = data_dec_csto$source_domain)          # MSE-optimal bw (mserd) auto-selected
```
(A per-source z-scored twin `model_placebo_aligned_z` on `sentiment_z` with
`covs = ~ topic_clean - 1` can be added to mirror the S12 raw+z pairing — see Q2.)

Notes vs. the main placebo: `source_domain` is dropped from `covs` because within a single
country×state-owned cell the source set is small and collinear with clustering; `country`
is retained (4 aligned countries). This mirrors how `06C` builds `covs` for the CSTO-only
`model5a_csto` (topic FE, cluster by source).

**Reported numbers (Task B):** Dec-7 placebo estimate, 95% CI, p-value, MSE-optimal
bandwidth, and N for the allied group (state-owned, non-military).

**Table:** new appendix table, format identical to `table_s12_placebo` (same gt columns,
header, footnote wording adapted, `save_table(..., "prob")`, added to the `fix_gt_caption`
loop). Proposed name **`table_s13_placebo_aligned`** (→ `figures/tables/prob/…tex + .html`).
I will **not** touch `main.tex`/appendix `.tex`; you can `\input` the new table where you
want it.

**Open design choice → see Questions Q2 (estimation path) and Q3 ("one for each country").**

---

## Files this will touch (execution phase, after your review)

1. `scripts/06C_russian_alignment_analysis_prob.Rmd` — add the pre-trend figure chunk and
   the CSTO-state placebo model chunk; add the new model(s) to `results_het_prob`.
2. `scripts/08a_publication_outputs.Rmd` — assemble + save `table_s13_placebo_aligned`;
   add it to the `fix_gt_caption` loop and the summary block.
3. `README.md` and `scripts/README.md` — document the new figure, table, and outputs
   (both are noted as needing updates and not treated as gospel).
4. **Not touched:** `main.tex`, appendix `.tex` files.

## Verification step (planned)

After execution: re-read the generated `.tex`/`.png`, sanity-check that the pre-trend slopes
and placebo estimate/CI/p/bw/N print consistently between the console summary and the table,
confirm the placebo N equals the CSTO-state non-military pre-invasion row count, and diff the
edited `.Rmd`s to confirm no unrelated changes.

---

## Decisions (locked, 2026-07-01)

- **Q1 — Task A x-axis & window → calendar-date x-axis, trimmed to the buildup window
  (2021-06-01 → 2022-06-01), linear pre-invasion fit only** (no LOESS).
- **Q2 — Task B estimation path → `rdrobust` on the per-source z-scored outcome
  (`sentiment_z`) only** (MSE-optimal "mserd" bandwidth, `cluster = source_domain`). No raw
  twin, no WCR-bootstrap path. One placebo estimate.
- **Q3 — "one for each country" → one pooled analysis across the 4 aligned countries using
  all their state-owned sources**, with source-level z-score adjustment (`sentiment_z`
  computed per `source_domain`). Not four separate per-country/per-source analyses; the
  z-scoring absorbs source/country baseline differences. Clustered by `source_domain`.
- **Q5 — Execution → I write the code (style-matched) into 06C/08a + README updates; Donald
  runs the pipeline in RStudio.** R is not available in this sandbox, so I cannot produce the
  actual PNG/.tex/numbers here — the code is written so that running 06C then 08a prints the
  required summary numbers and writes the figure/table to their standard locations.

## Revision (2026-07-01, round 2)

After first review, two changes were requested and are now implemented:

- **Task B → four per-country placebos (replacing the pooled test).** One `rdrobust` per
  aligned country (Armenia, Azerbaijan, Belarus, Kazakhstan): state-owned, non-military,
  pre-invasion, Dec-7 cutoff, source-level z-scored outcome, MSE-optimal bandwidth.
  **SEs use rdrobust's default (nearest-neighbor HC), not source clustering**, because each
  country has only 2-3 state-owned sources (too few clusters). Degenerate single-article
  sources (NaN z) and empty topic levels are dropped within each country subset. Models are
  stored as the named list `placebo_aligned_models` in `06_alignment_results_prob.rds`.
  `table_s13_placebo_aligned` now shows the **four countries side-by-side as columns**
  (rows = Estimate, Std. Error, 95% CI, p-value, Bandwidth, N).
- **Task A → add a later-start replica figure.** `pretrend_by_country_aligned_dec.png`
  duplicates the pre-trend figure with the display window starting **2021-12-01** instead of
  2021-06-01, to show the pre-invasion slope is not an artifact of a long window. The
  original 2021-06-01 figure is retained. No separate slope printout for the Dec-1 window.

### Consequences for the specs above
- **Task A:** `agg_pretrend` filtered to `date_publish` within [2021-06-01, 2022-06-01];
  single `geom_smooth(method = "lm")` on the pre-Feb-24 subset; per-country linear slope
  (per day and per 30 days) printed via `cat()`.
- **Task B:** outcome is `sentiment_z` (per-source z-score) on the pooled CSTO state-owned
  non-military pre-invasion sample; `covs = model.matrix(~ topic_clean - 1)` (topic FE only,
  as in `model5a_csto_z`); single `table_s13_placebo_aligned` row.
