# Presentation Figure Numbers

Written by `scripts/12_presentation_figures.Rmd`.

## Figure 5: Articles and Outlets by Country and Ownership

Russia-related, non-Ukraine articles, August 2021 to August 2022.

| Block | Country | Ownership | Articles | Outlets |
|---|---|---|---|---|
| Treaty clients | Armenia | Independent | 21,853 | 5 |
| Treaty clients | Armenia | State-owned | 3,965 | 2 |
| Treaty clients | Belarus | Independent | 7,155 | 3 |
| Treaty clients | Belarus | State-owned | 12,429 | 3 |
| Treaty clients | Azerbaijan | Independent | 15,648 | 5 |
| Treaty clients | Azerbaijan | State-owned | 2,849 | 2 |
| Treaty clients | Kazakhstan | Independent | 4,821 | 4 |
| Treaty clients | Kazakhstan | State-owned | 1,352 | 2 |
| Non-treaty states | Kosovo | Independent | 16,792 | 4 |
| Non-treaty states | Kosovo | State-owned | 2,619 | 1 |
| Non-treaty states | Serbia | Independent | 15,710 | 4 |
| Non-treaty states | Serbia | State-owned | 1,157 | 1 |
| Non-treaty states | Moldova | Independent | 8,259 | 5 |
| Non-treaty states | Moldova | State-owned | 1,178 | 1 |
| Non-treaty states | Georgia | Independent | 4,707 | 2 |
| Non-treaty states | Georgia | State-owned | 1,362 | 1 |
| NATO members | Turkey | Independent | 18,943 | 5 |
| NATO members | Turkey | State-owned | 5,710 | 1 |
| NATO members | Hungary | Independent | 12,430 | 5 |
| NATO members | Hungary | State-owned | 3,085 | 1 |
| NATO members | Albania | Independent | 9,000 | 3 |
| NATO members | Albania | State-owned | 3,032 | 2 |

| Ownership | Articles | Outlets |
|---|---|---|
| Independent | 135,318 | 44 |
| State-owned | 38,738 | 17 |

Total: 174,056 articles, 61 outlets. `balkaninsight.com` publishes under both Kosovo and Serbia, so the per-country outlet counts sum to 62.

## Main Results: Pre-Period Specification

Outcome: `sentiment_z_pre_tdm`, with pre-invasion values from each sample's full window.

### Estimates

| Hypothesis | Estimate | SE | p | Inference | Window (days) | Articles |
|---|---|---|---|---|---|---|
| H1 (rdrobust, Conventional row) | -0.207 | 0.041 | 0.000 | Clustered | 24.8 | 32,743 |
| H1 (rdrobust, Robust row) | -0.186 | 0.043 | 0.000 | Robust bias-corrected, clustered | 24.8 | 32,743 |
| H2 State-owned x Treatment | 0.263 | 0.078 | 0.020 | Wild cluster bootstrap, B = 99999 | 42.3 | 31,379 |
| H3 Treaty client x Treatment | -0.433 | 0.121 | 0.019 | Wild cluster bootstrap, B = 99999 | 40.5 | 5,721 |

### For Comparison: Stored Table S15 (Pre-Invasion Values from Bandwidth Rows Only)

| Model | Version | Estimate | Bootstrap p |
|---|---|---|---|
| H2 matched | (1) main | 0.222 | 0.032 |
| H2 matched | (4) both | 0.281 | 0.005 |
| H3a matched | (1) main | -0.380 | 0.027 |
| H3a matched | (4) both | -0.353 | 0.004 |

### Jumps by Group

From the plotted lines. Clustered inference only; H3 groups have very few outlets.

| Stage | Group | Pre at cutoff | Post at cutoff | Jump (SD) | Clustered SE | Clustered p | Articles | Outlets |
|---|---|---|---|---|---|---|---|---|
| H1 full range | All outlets | -0.016 | -0.268 | -0.252 | 0.020 | 0.000 | 130,376 | 60 |
| H1 window | All outlets | -0.145 | -0.412 | -0.268 | 0.030 | 0.000 | 32,743 | 60 |
| H2 full range | Independent | -0.021 | -0.316 | -0.294 | 0.035 | 0.000 | 70,717 | 30 |
| H2 full range | State-owned | 0.013 | -0.153 | -0.166 | 0.046 | 0.004 | 22,535 | 13 |
| H2 window | Independent | -0.077 | -0.458 | -0.382 | 0.032 | 0.000 | 25,007 | 30 |
| H2 window | State-owned | -0.049 | -0.168 | -0.119 | 0.073 | 0.129 | 6,372 | 13 |
| H3 full range | Treaty client | 0.010 | -0.196 | -0.206 | 0.042 | 0.001 | 17,733 | 9 |
| H3 full range | Non-treaty state | 0.018 | -0.055 | -0.073 | 0.122 | 0.593 | 4,802 | 4 |
| H3 window | Treaty client | -0.029 | -0.313 | -0.284 | 0.089 | 0.013 | 4,097 | 9 |
| H3 window | Non-treaty state | -0.076 | 0.072 | 0.149 | 0.093 | 0.207 | 1,624 | 4 |

### R1: Raw Translations Inside the H1 Window

| Group | Side | Articles | Share coded -1 | Raw article mean | Raw daily mean |
|---|---|---|---|---|---|
| All outlets | Before | 9,147 | 0.228 | -0.169 | -0.142 |
| All outlets | After | 23,596 | 0.355 | -0.303 | -0.291 |

### R2: Raw Translations Inside the H2 Window

| Group | Side | Articles | Share coded -1 | Raw article mean | Raw daily mean |
|---|---|---|---|---|---|
| Independent | Before | 7,064 | 0.222 | -0.165 | -0.159 |
| Independent | After | 17,943 | 0.357 | -0.307 | -0.296 |
| State-owned | Before | 2,126 | 0.175 | -0.082 | -0.091 |
| State-owned | After | 4,246 | 0.203 | -0.083 | -0.094 |

### R3: Raw Translations Inside the H3 Window

| Group | Side | Articles | Share coded -1 | Raw article mean | Raw daily mean |
|---|---|---|---|---|---|
| Non-treaty state | Before | 577 | 0.341 | -0.269 | -0.214 |
| Non-treaty state | After | 1,047 | 0.299 | -0.218 | -0.206 |
| Treaty client | Before | 1,199 | 0.117 | -0.010 | -0.036 |
| Treaty client | After | 2,898 | 0.168 | -0.031 | -0.046 |

### Outlets Dropped by the Pre-Period Outcome

| Sample | Outlet | Country | Articles |
|---|---|---|---|
| H1 | voceabasarabiei.md | Moldova | 112 |
| H2 | voceabasarabiei.md | Moldova | 112 |

### Points Outside the `h3` Panels (y range +/-1.1)

| Stages | Day | Group | Daily mean (SD) | Articles |
|---|---|---|---|---|
| Full range (s1-s5) | -200 | Treaty client | -1.11 | 4 |
| Full range (s1-s5) | -187 | Non-treaty state | -1.42 | 1 |
| Full range (s1-s5) | -117 | Non-treaty state | 1.26 | 2 |
| Full range (s1-s5) | -39 | Non-treaty state | 1.93 | 1 |
| Full range (s1-s5) | 115 | Non-treaty state | -1.68 | 1 |
| Full range (s1-s5) | 164 | Treaty client | -1.23 | 3 |
| Full range (s1-s5) | 181 | Non-treaty state | 1.17 | 13 |
| Zoomed (s6-s8) | -39 | Treaty client | -1.48 | 4 |
| Zoomed (s6-s8) | -39 | Non-treaty state | 1.93 | 1 |

### Appendix: Lowess Version of `h3_s4`

Non-robust, span 2/3, full range. Values at the cutoff in within-outlet SD.

| Group | Before | After | Lowess jump | Straight-line jump |
|---|---|---|---|---|
| Treaty client | -0.060 | -0.172 | -0.112 | -0.206 |
| Non-treaty state | -0.008 | 0.038 | 0.047 | -0.073 |

