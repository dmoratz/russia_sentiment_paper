# Job Talk Figures: Hand-Back Report

For the chat that wrote `job-talk-figure-specs.md`. This covers what was built, where the spec
and the data disagree, and the numbers confirmed for the talk.

All figures are in `figures/presentation/`, built by `scripts/12_presentation_figures.Rmd`, which
rendered cleanly with the full wild bootstrap (B = 99999). The numbers in sections 3 and 4 also
appear in `figures/presentation/figure_numbers.md`.

## 1. What changed from the spec

- **Main click-throughs use a new outcome.** H1, H2 and H3 now plot `sentiment_z_pre_tdm`: a
  within-outlet z-score on pre-invasion means and SDs, minus pre-invasion topic means on that
  scale, with no topic fixed effects. The y axis reads "Sentiment toward Russia (within-outlet
  SD)", and jump labels are in SD rather than the raw scale the spec asked for.
- **Pre-invasion values come from the full window.** They use all pre-invasion articles in each
  hypothesis's sample, not only bandwidth rows.
- **Raw-score versions moved to the appendix.** `h1_raw_full_present.png`,
  `h2_raw_full_present.png` and `h3_raw_full_present.png` are full range, with no zoom or clicks.
- **Scatter points use days; fit lines use probabilistic time.** Lines are plain straight fits
  with no triangular weights.
- **Every file name ends in `_present`,** so `.tex` references need that suffix.
- **The click-throughs are longer than the spec's, treaty clients are purple,** and there is a
  new lowess appendix figure. See section 2.
- **Deck edits belong to Donald.** No `.tex` file was changed.

## 2. Deck changes required

**The slides need to include every stage below.** The stage numbers changed, so an existing
`\includegraphics{h2_s3_present}` now shows a different figure. Old `h1_s3`, `h2_s3` and `h3_s3`
are now the last stage of each set. The full-range and zoomed stages each share one set of axes,
so nothing moves between clicks within a range.

### H1: five stages

| File | Shows | Was |
|---|---|---|
| `h1_s1_present.png` | Dots, full range | `h1_s1` |
| `h1_s2_present.png` | Dots and lines, full range | `h1_s2` |
| `h1_s3_present.png` | Same, with the ±24.8-day window shaded | New |
| `h1_s4_present.png` | Dots only, zoomed to the window | New |
| `h1_s5_present.png` | Dots and lines, zoomed to the window | `h1_s3` |

### H2 and H3: eight stages each

H2's first group is Independent and its second is State-owned. H3's first group is Non-treaty
state and its second is Treaty client.

| File | Shows | Was |
|---|---|---|
| `h2_s1` / `h3_s1` | First group's dots, full range | New |
| `h2_s2` / `h3_s2` | Both groups' dots | New |
| `h2_s3` / `h3_s3` | Adds the first group's line | New |
| `h2_s4` / `h3_s4` | Adds the second group's line | Old `h2_s2` / `h3_s2` |
| `h2_s5` / `h3_s5` | Same, with the window shaded (±42.3 / ±40.5 days) | New |
| `h2_s6` / `h3_s6` | Both groups' dots, zoomed to the window | New |
| `h2_s7` / `h3_s7` | Adds the first group's line and jump label | New |
| `h2_s8` / `h3_s8` | Adds the second group's line and jump label | Old `h2_s3` / `h3_s3` |

Old `h2_s1` and `h3_s1` (one group's dots and line, alone) are replaced: state dots now appear
before any line is drawn.

### Sample by country: three stages

| File | Shows | Was |
|---|---|---|
| `sample_by_country_s1_present.png` | Countries and axes, no bars | New |
| `sample_by_country_s2_present.png` | Independent bars | `sample_by_country_s1` |
| `sample_by_country_s3_present.png` | Independent and state-owned bars | `sample_by_country_s2` |

### Sample map: four stages

| File | Shows | Was |
|---|---|---|
| `sample_map_s1_present.png` | Nothing colored, all names in light grey, no legend | New |
| `sample_map_s2_present.png` | Treaty clients; Kyrgyzstan and Tajikistan hatched, "not in corpus" | `sample_map_s1` |
| `sample_map_s3_present.png` | Adds non-treaty states | `sample_map_s2`, with changes |
| `sample_map_s4_present.png` | Adds NATO members | `sample_map_s3`, with changes |

**The slides need all four.** In stages 3 and 4, Kyrgyzstan and Tajikistan go back to light grey:
no hatching, no "not in corpus" note, a grey name and no legend row. Stage 1 keeps the dark Ukraine
outline and the Russia and Ukraine labels, so the frame doesn't change between clicks.

### UN vote map: labeled by vote

The legend now reads "Voted against", "Abstained", "In sample, voted for" and "In sample, not a UN
member". Votes were checked against the [UN voting record for
A/ES-11/L.1](https://www.un.org/sites/un2.un.org/files/voting_rec_a-es-11-l.1.pdf) (March 2, 2022;
141-5-35):

| Vote | Countries |
|---|---|
| For | Albania, Georgia, Hungary, Moldova, Serbia, Turkey |
| Abstained | Armenia, Kazakhstan, Kyrgyzstan, Tajikistan |
| Against | Belarus |
| No vote recorded, shown as abstained by Donald's choice | Azerbaijan |
| Not on the record, because it is not a UN member | Kosovo |

**Any talking point that says all non-treaty states voted for the resolution must leave out
Kosovo.** Any text calling Azerbaijan an abstainer is a simplification of the same kind.

### H3 y range

All H3 stages (`h3_s1`-`s8`) and `h3_s4_lowess_present.png` now use a y range of ±1.1. A few
low-volume days fall outside it and are listed in `figure_numbers.md`.

### Appendix addition: lowess version of `h3_s4`

`h3_s4_lowess_present.png` is new and belongs in the appendix. It has the same sample, outcome,
points and axes as `h3_s4`, with a smoother in place of the straight lines.

- **Method:** local linear with tricube weights, span 2/3, fitted to articles separately for each
  group on each side of the cutoff. It is the **non-robust** version, because the robustness step
  in `lowess()`'s default pulls the curve toward the most common sentiment value and nearly erases
  the drop.
- **Implementation:** `loess()` with `family = "gaussian"`, which matches `lowess(iter = 0)` to
  within 0.0005 SD on the one side tested and also gives standard errors. Bands are pointwise 95%
  and **not clustered**, so they are narrower than clustered bands would be.
- **Do not quote the straight-line jumps for this figure:**

| Group | Lowess jump (SD) | `h3_s4` straight-line jump (SD) |
|---|---|---|
| Treaty client | -0.112 | -0.206 |
| Non-treaty state | +0.047 | -0.073 |

- **Other chat's numbers:** the −0.024 (robust) and −0.257 (non-robust) came from a sketch of this
  method and are not this figure's numbers. They were not reproduced exactly. The closest match is
  the treaty-client side of the zoomed H3 window (−0.040 and −0.242), not the full range.

### Colors

**Anything drawn or redrawn from here on, including TikZ and slide text, must use these colors.**
The spec's `#E74C3C` treaty red and the vote map's red and orange were replaced because red/green
color blindness is common.

| Use | Color | Replaces |
|---|---|---|
| Treaty client | `treatyClient` = `#8E44AD` | `#E74C3C` |
| Vote map, voted against | `#4A235A` | `suppressRed`, `#C0392B` |
| Vote map, abstained | `#A569BD` | `mLightBrown`, `#EB811B` |
| Floor figure, non-treaty independent | `indepMedia` = `#3498DB` | `nonTreaty`, `#2ECC71` |
| Vote map, voted for | `nonTreaty` at 60% opacity | `nonTreaty` at 35% |
| Vote map, not a UN member (Kosovo) | `nonTreaty` at 20% opacity | New |

- **Treaty client is now purple, `#8E44AD`, because red/green color blindness is common.** Set
  `treatyClient` to this in the deck preamble, and use it for any treaty-colored text and the
  TikZ ghost. In simulated protanopia, purple vs non-treaty green has a color distance of 79.8,
  against 4.8 for the old red. This applies to every treaty-colored figure: the H3 sets,
  `h3_raw_full`, `state_align_discs`, the sample maps and `pretrend_by_country_treaty`.
- **Non-treaty independent in `nontreaty_floor_present.png` is now `indepMedia`, `#3498DB`,** the
  same blue as Independent in the H2 figures. Its state line stays `nonTreatyText`, matching
  Non-treaty state in H3.
- **`un_vote_map_present.png` no longer uses red and orange.** Voted against is dark purple,
  `#4A235A`, and abstained is light purple, `#A569BD`, so all six treaty clients read as one purple
  family. The non-treaty green went from 35% to 60% opacity, matching the sample maps, because the
  lighter green was hard to tell from the grey of Russia under color blindness. Any deck text
  colored with `suppressRed` to match this map needs updating.

## 2a. Slide titles and deck items to change

| Item | Spec says | Final numbers | Action |
|---|---|---|---|
| `h1_s2` title | "A Drop of 0.18 Standard Deviations" | The plotted full-range drop is **0.25 SD** (-0.252) | **Change the number** |
| Spec `h2_s2` title (now `h2_s4`) | "State-Owned Outlets Dropped Half as Far" | Full range: -0.166 vs -0.294, a ratio of 0.56. Window: -0.119 vs -0.382, about a third | Holds for this slide, which is full range. Do not repeat "half" for the window |
| Spec `h3_s1` title (now `h3_s1`-`s3`) | "Non-Treaty State Media Did Not Move" | Full range: -0.073 (clustered p = .593). Window: +0.149 (p = .207) | Holds |
| Spec `h3_s2` title (now `h3_s4`) | "Treaty-Client State Media Fell" | Full range: -0.206 (p = .001). Window: -0.284 (p = .013) | Holds |
| Spec `h3_s3` title (now `h3_s8`) | "The Treaty Line Is the One That Moved" | Interaction -0.433, bootstrap p = .019 | Holds. The numbers do not test the "opposite of suppression" clause |
| TikZ ghost for R3 | Treaty line above non-treaty line | Both lines now start near zero (see below) | **Redraw** |
| Deck estimates | H1 -0.184, H2 +0.222, H3 -0.38 | See section 3 | **Decide which set the talk quotes** |

Lines for the ghost redraw, as values at the cutoff (SD):

| Range | Group | Before | After |
|---|---|---|---|
| Full | Treaty client | 0.010 | -0.196 |
| Full | Non-treaty state | 0.018 | -0.055 |
| Window (±40.5 days) | Treaty client | -0.029 | -0.313 |
| Window (±40.5 days) | Non-treaty state | -0.076 | 0.072 |

## 3. Numbers confirmed for the talk

### Main estimates

| Hypothesis | Estimate (SD) | SE | p | Inference | Window | Articles |
|---|---|---|---|---|---|---|
| H1, `rdrobust` Conventional row | -0.207 | 0.041 | <.001 | Clustered | ±24.8 days | 32,743 |
| H1, `rdrobust` Robust row | -0.186 | 0.043 | <.001 | Robust bias-corrected, clustered | ±24.8 days | 32,743 |
| H2, State-owned x Treatment | +0.263 | 0.078 | .020 | Wild cluster bootstrap | ±42.3 days | 31,379 |
| H3, Treaty client x Treatment | -0.433 | 0.121 | .019 | Wild cluster bootstrap | ±40.5 days | 5,721 |

- **H1 rows:** both come from one `rdrobust` call, with Model 6's h (24.8 days) and b (45.6
  days). The Conventional row is the local linear estimate, which is the row the paper's tables
  report. The Robust row is the bias-corrected estimate with its robust SE.
- **Samples:** H1 is non-military, all countries, unmatched, with the window held at Model 6's.
  H2 is non-NATO, non-military, on the Table 2 Model 6 matched rows. H3 is state media, non-NATO,
  non-military, on the Table 4 Model 5 matched rows.
- **Check on the matched rows:** the script stops unless those rows reproduce the stored main
  estimates (+0.222, -0.380). Both passed.
- **Lines vs estimates:** in the window, the plotted group jumps reproduce the H2 and H3
  estimates exactly (-0.119 - (-0.382) = +0.263; -0.284 - 0.149 = -0.433). H1 does not match in
  the same way: the plotted window line drops -0.268, against `rdrobust`'s -0.207.

### Jumps by group (from the plotted lines)

Clustered inference only. The H3 groups have 9 and 4 outlets, so treat those p-values with care.

| Stage | Group | Jump (SD) | Clustered p | Articles | Outlets |
|---|---|---|---|---|---|
| H1 full range | All outlets | -0.252 | <.001 | 130,376 | 60 |
| H1 window | All outlets | -0.268 | <.001 | 32,743 | 60 |
| H2 full range | Independent | -0.294 | <.001 | 70,717 | 30 |
| H2 full range | State-owned | -0.166 | .004 | 22,535 | 13 |
| H2 window | Independent | -0.382 | <.001 | 25,007 | 30 |
| H2 window | State-owned | -0.119 | .129 | 6,372 | 13 |
| H3 full range | Treaty client | -0.206 | .001 | 17,733 | 9 |
| H3 full range | Non-treaty state | -0.073 | .593 | 4,802 | 4 |
| H3 window | Treaty client | -0.284 | .013 | 4,097 | 9 |
| H3 window | Non-treaty state | +0.149 | .207 | 1,624 | 4 |

### Raw translations inside each window

| Group | Share coded -1, before → after | Raw article mean, before → after |
|---|---|---|
| All outlets (H1 window) | .228 → .355 | -0.169 → -0.303 |
| Independent (H2 window) | .222 → .357 | -0.165 → -0.307 |
| State-owned (H2 window) | .175 → .203 | -0.082 → -0.083 |
| Non-treaty state (H3 window) | .341 → .299 | -0.269 → -0.218 |
| Treaty client (H3 window) | .117 → .168 | -0.010 → -0.031 |

### Sample

- 174,056 articles and 61 outlets: 135,318 articles from 44 independent outlets, and 38,738 from
  17 state-owned outlets.
- `balkaninsight.com` publishes under both Kosovo and Serbia, so per-country outlet counts sum
  to 62.
- The country-by-ownership table is in `figure_numbers.md`.

## 4. Full-window values vs stored Table S15

Donald chose full-window pre-invasion values. Table S15 in `scripts/09_preperiod_diagnostics.Rmd`
still computes them from bandwidth rows only, so **`09` needs updating** for the paper and talk
to agree.

| Model | S15 (1) main | S15 (4) both, bandwidth rows | Full window, used here |
|---|---|---|---|
| H2 | +0.222 (p = .032) | +0.281 (p = .005) | **+0.263 (p = .020)** |
| H3 | -0.380 (p = .027) | -0.353 (p = .004) | **-0.433 (p = .019)** |

Both remain significant at the 5% level, but the p-values are about four to five times S15's
"both" values. Any talking point that relies on p < .01 no longer holds under the full window.

## 5. Outlets dropped

- **`insajder.net`** is excluded everywhere because its sentiment has zero variance. This is what
  takes the count from 62 to 61 outlets.
- **`voceabasarabiei.md`** (Moldova, 112 non-military articles) drops from the H1 and H2 samples
  under the new outcome. All of its articles are post-invasion, so it has no pre-invasion baseline.

## 6. Open items

- **`sensitivity_ovb_csto_present.png`** is relabeled to "Treaty client" in `06a`. It still shows
  the Table 4 Model 5 estimate (-0.38), not the talk's -0.433, and it keeps a built-in title. It
  was regenerated by running `06a` as far as this figure with the stored matched bootstrap SE;
  no other `06a` output was rewritten.
- **Duplicate files.** `invasion_on_sentiment_present_nonmil.png` is byte-identical to
  `h1_raw_full_present.png`, and `state_align_discs_present_nonmil.png` to
  `h3_raw_full_present.png`. `invasion_discs_graph_present_nonmil.png` is not a duplicate of
  `h2_raw_full_present.png`: it uses all countries, while `h2_raw_full` is non-NATO.
- **Some low-volume days are off the panel in the H3 stages,** which all use a y range of ±1.1.
  They are listed by stage in `figure_numbers.md`.
- **Photo.** `invasion_photo_present.png` is a copy at 1535 px, under the spec's 1600 px. Credit
  and usage rights still need confirming.
- **Old PNGs** in the earlier figure folders were left in place for Donald to archive.

## 7. Spec disagreement log

| # | Spec location | Spec says | Actual | Resolution |
|---|---|---|---|---|
| 1 | Figure 1 | Six treaty clients + "remaining five of the eleven" | Corpus has 4 treaty clients and 7 others (11). Kyrgyzstan and Tajikistan are not in the corpus, so the map shows 13 | Map shows 13 |
| 2 | Figure 7 | Window from Table 1 Model 4 | Model 4 is all-topic, raw score. The deck's -0.184 and the non-military sample are Model 6 | Model 6's window |
| 3 | Figures 7-9 | Windows read from "the model object" (variant not named) | Deck estimates match the probabilistic models, not days | Probabilistic windows, daily points |
| 4 | `h1_s2` title | 0.18 SD drop | 0.18 was Model 6's windowed estimate. Plotted full-range drop is now 0.25 SD | Change the title |
| 5 | `h2_s2` title | State-owned "dropped half as far" | Holds on the final outcome at full range (0.56). Raw non-NATO full-range lines give about a quarter (-0.042 vs -0.156) | Title holds for the main figure |
| 6 | Figure 8 | Rebuild the existing file as Model 6's non-NATO sample | The existing file uses all countries, so this changes the sample, not only the colors | Non-NATO |
| 7 | Figure 7 | "Local linear fits" | Existing figures use unweighted straight-line fits | Plain lines |
| 8 | Figure 5 | 61 outlets | 62 distinct, 61 after dropping `insajder.net`. Per-country counts sum to 62 | Exclude; noted in table |
| 9 | Figure 11, floor | One group color for a two-series figure | Two series in one color can't be told apart | Green for state, H2's blue for independent |
| 10 | Figure 1 | Reuse `region_map.png` extent if suitable | No projected CRS, and it cuts off Kazakhstan | New extent |
| 11 | Figures 2-3 | At least 1600 px wide | Screenshot is 1321 px; photo is 1535 px | Upscaled screenshot; copied photo |
| 12 | Delivery | `presentation/figures/`; scripts `make_*.R` | Donald chose `figures/presentation/` and one Rmd | Followed Donald |
| 13 | Figure 4 | `ggpattern`; `magick` as fallback | Neither installed; spec allows a line overlay | Line overlay; `magick` installed |
| 14 | Figure 11 list | Three appendix regenerations | Deck source also uses `invasion_on_sentiment_present.png` | Recolored and moved |
| 15 | Color names | `indepMedia` `#3498DB`, `stateMedia` `#E67E22` | Existing figures used dodgerblue and forestgreen | Spec values |
| 16 | Figures 7-9 | Click-throughs and jump labels on the raw score | Donald moved these to the pre-period specification | Followed Donald; raw versions in appendix |
| 17 | Figure 9 | Treaty line above non-treaty, matching the ghost | True on the raw score (0.025 vs -0.264), but both start near zero on the new outcome | Ghost needs redrawing |
| 18 | File names | No `_present` | Donald wants `_present` on every file | Followed Donald |
| 19 | Figure 1 | Russia west of 95E fully inside the frame | Fitting the Arctic coast forces an 8,500 km frame and puts the Balkans under the legend | East edge at 95E; Russia runs off the top |
| 20 | Figure 1 | Natural Earth boundaries | Natural Earth draws Crimea as Russian | Crimea moved to Ukraine |
| 21 | Spec `h3_s3` (now `h3_s6`-`s8`) | y range "may tighten" | Two low-volume days stretch the axis to about -1.5 and +1.9 | Fixed at ±1.1; points listed; see also #31 |
| 22 | Figure 1 | `ggrepel::geom_label_repel` | Draws a border that can't be removed with this `ggplot2`; fixed positions also keep the maps identical | Plain labels with leader lines |
| 23 | Language rule | Legends never say "aligned" | `sensitivity_ovb_csto_present.png` said "Russia-Aligned" | Relabeled in `06a` |
| 24 | Figure 1 | Four legend swatches, including "Did not vote" | Donald treats Azerbaijan's non-vote as a technical difference | Azerbaijan shown as abstained; three swatches |
| 25 | Color names | `treatyClient` = `#E74C3C` | Red and green are hard to separate under common color blindness | Purple, `#8E44AD`; deck preamble needs updating |
| 27 | Figure 1 | `suppressRed` against, `mLightBrown` abstained, `nonTreaty` at 35% | Same color-blindness concern | Against `#4A235A`, abstained `#A569BD`, `nonTreaty` at 60% |
| 29 | Figure 1 | Legend says "In sample, no treaty with Russia" | Donald wants these countries labeled by how they voted. The UN record shows all voted for, except Kosovo, which is not a UN member | "In sample, voted for"; Kosovo gets "In sample, not a UN member" |
| 30 | Figure 4 | Three stages; Kyrgyzstan and Tajikistan hatched throughout | Donald wants a blank first stage and the hatching on the treaty stage only | Four stages |
| 31 | Figure 9 | Only `h3_s3` y range "may tighten" | Outliers also flatten the full-range stages | All H3 stages and the lowess figure at +/-1.1 |
| 28 | Appendix | No lowess figure | Donald added a non-robust lowess version of `h3_s4` | `h3_s4_lowess_present.png`; slides need it in the appendix |
| 26 | Figures 5, 7-9 | Three stages for H1-H3, two for the sample bars | Donald wants slower builds | H1 five stages, H2 and H3 eight each, bars three; slides need all of them |
