# Presentation Figures Plan

Source spec: `C:\Users\skybl\Downloads\job-talk-figure-specs.md` (Figures 1-11), as changed by
the decisions below.

**How to use this file:** tick a box as soon as its step is done, not in batches, so an
interrupted session can resume from here. Add anything the spec gets wrong to the
disagreement log as it turns up.

**Current status:** complete. Final numbers and the disagreement summary are in `plans/presentation_figures_spec_report.md`.

## Ground rules

- **Never push to GitHub.** Donald handles all pushes. Do not commit unless asked.
- **No deck edits.** The deck lives on Overleaf and Donald updates every `.tex` file.
- **Do not delete or clear old PNGs.** Donald archives them later.
- **Do not rerun the pipeline scripts.** The new script reads saved data and models.
- **Coding conventions:** the new script is an R Markdown file modeled on `06a`: YAML header,
  an Overview listing inputs and outputs, a clear heading outline, labeled chunks, short
  explanatory prose before chunks, and clean comments.

## Final decisions

### Files and locations

- Script: `scripts/12_presentation_figures.Rmd`. Spec's three `make_*.R` scripts are not used.
- Output: `figures/presentation/`, via a new `FIGURES_PRESENTATION` constant in `00_setup.R`.
- Every figure file carries `_present`, e.g. `h1_s1_present.png`, `un_vote_map_present.png`.

### Main results: H1, H2, H3 click-throughs

- **Outcome:** `sentiment_z_pre_tdm`, `09` spec 4, "both": within-outlet z-score on pre-invasion
  source means and SDs, then minus pre-invasion topic means on that scale. No topic fixed effects.
- **Pre-period values come from the full window:** all pre-invasion articles in each
  hypothesis's sample, NOT the bandwidth rows S15 uses. Donald will update `09`.
- **H1:** non-military, all countries, unmatched, `rdrobust`, window held at Model 6's ±24.8 days.
- **H2:** non-NATO, non-military. Zoom stage on the Table 2 Model 6 matched rows, ±42.3 days.
- **H3:** state media, non-NATO, non-military. Zoom stage on the Table 4 Model 5 matched rows,
  ±40.5 days.
- **Scatter points use days** (`running`). **Fit lines use probabilistic time** in days. Plain
  straight lines, no triangular weights.
- **Y axis:** "Sentiment toward Russia (within-outlet SD)". Jump labels in SD.
- **Numbers:** SD jumps and estimates, wild bootstrap at B = 99999 for H2 and H3, plus raw share
  coded -1 and raw means.

### Appendix

- Raw-score, full-range, no zoom, no click-through: `h1_raw_full_present.png`,
  `h2_raw_full_present.png`, `h3_raw_full_present.png`.
- Figures 10 and 11, the floor plot, and the unstaged `_nonmil` plots stay on the raw score.

### Other settled choices

- **Colors:** spec / Overleaf hex values, in one `pal` list.
- **Vote map:** 13 countries. Six treaty clients by UN vote; the other seven green. Azerbaijan is grouped with the abstentions. Non-treaty and NATO countries are labeled by vote, from the UN record; Kosovo is labeled not a UN member. Against and abstained are dark and light purple.
- **Exclude `insajder.net`** everywhere, for 61 outlets. Note that `balkaninsight.com` spans
  Kosovo and Serbia, so per-country outlet counts sum to 62.
- **H3 y range:** +/-1.1 at every stage, including the lowess figure.
- **Figure 6** uses the non-Ukraine sample.
- **Floor figure:** `nonTreatyText` for state media, `indepMedia` for independent media, matching H2.
- **Treaty client color:** purple, `#8E44AD`, because red/green color blindness is common. The deck
  preamble needs the same change.
- **Figure 2:** stack two crops and upscale to 1600 px. **Figure 3:** copy `invasion_photo.png`.
- **Hatching:** overlaid 45-degree lines, no `ggpattern`. Install `magick`.

### Existing presentation figures

| Existing figure | From | Action | New file |
|---|---|---|---|
| `invasion_on_sentiment_present` | 04b | Move, recolor | same name |
| `invasion_on_sentiment_present_nonmil` | 04b | Move, recolor | same name |
| `invasion_discs_graph_present` | 05b | Move, recolor | same name |
| `invasion_discs_graph_present_nonmil` | 05b | Move, recolor | same name |
| `invasion_discs_graph_present_neutral` | 05b | Move, recolor | same name |
| `neutral_floor_present` | 05b | Move, replace | `nontreaty_floor_present` |
| `state_align_discs_present` | 06b | Move, recolor | same name |
| `state_align_discs_present_nonmil` | 06b | Move, recolor | same name |
| `pretrend_by_country_aligned_present` | 06b | Move, replace | `pretrend_by_country_treaty_present` |
| `sensitivity_ovb_csto_present` | 06a | Stays; save path only | same name |

The paper's `pretrend_by_country_aligned.png` chunk stays in `06b`.

## Phase 1: Setup

- [x] Add `FIGURES_PRESENTATION` to `scripts/00_setup.R` and its directory list
- [x] Install `magick`
- [x] Create `scripts/12_presentation_figures.Rmd` with outline, `pal` list and shared helpers
- [x] Remove moved chunks from `04b`, `05b`, `06b`; confirm nothing later depends on them
- [x] Change the save path in `06a`; copy the existing PNG so the folder is complete
- [x] Add the new script to `scripts/master.Rmd` and the README script tables

## Phase 2: Maps

- [x] Shared `countries` frame, projection and extent; Kosovo matched correctly
- [x] Figure 1: `un_vote_map_present.png`
- [x] Figure 4: `sample_map_s1_present.png` (blank) through `_s4_`; Kyrgyzstan and Tajikistan hatched in `_s2_` only
- [x] Check at 250 px wide: labels legible, no overlaps, no country clipped

## Phase 3: Descriptive figures

- [x] Figure 5: `sample_by_country_s1_present.png` (no bars), `_s2_` (independent), `_s3_` (both)
- [x] Figure 5: country x ownership Markdown count table
- [x] Figure 6: `articles_per_day_s1_present.png`, `_s2_`

## Phase 4: Main results

- [x] Build the pre-period outcome, H1 / H2 / H3 samples, matched rows
- [x] Check matched main estimates still reproduce (+0.222, -0.380) before using the rows
- [x] Figure 7: `h1_s1_present.png` through `_s5_`
- [x] Figure 8: `h2_s1_present.png` through `_s8_`
- [x] Figure 9: `h3_s1_present.png` through `_s8_`
- [x] Estimates and bootstrap; R1-R3 numbers
- [x] Axes identical across the stages that share a range

## Phase 5: Appendix and moved figures

- [x] `h1_raw_full_present.png`, `h2_raw_full_present.png`, `h3_raw_full_present.png`
- [x] `h3_s4_lowess_present.png`: non-robust, span 2/3, bands pointwise and not clustered
- [x] Figure 10: `pretrend_by_country_treaty_present.png`
- [x] Figure 11: `invasion_discs_graph_present.png`, `state_align_discs_present.png`
- [x] Figure 11: `nontreaty_floor_present.png`
- [x] `invasion_on_sentiment_present.png`, `invasion_on_sentiment_present_nonmil.png`
- [x] `invasion_discs_graph_present_nonmil.png`, `invasion_discs_graph_present_neutral.png`
- [x] `state_align_discs_present_nonmil.png`

## Phase 6: Non-R figures

- [x] Figure 2: `kazahk_media_screenshot_present.png`
- [x] Figure 3: `invasion_photo_present.png`

## Phase 7: Final checks and report

- [x] Render the new script from a clean R session
- [x] View every PNG; confirm banned legend words are gone ("aligned", "neutral", "Russia-aligned")
- [x] Write `figures/presentation/figure_numbers.md`
- [x] Write the hand-back report, `plans/presentation_figures_spec_report.md`

### Must appear in the final report

- [x] TikZ ghost for R3 needs redrawing: both lines now start near zero (log #17).
- [x] H2 title: "half as far" holds at full range but not in the window; confirm final numbers.
- [x] H3 titles: double check "Non-Treaty ... Did Not Move" and "Treaty ... Fell" on final
      numbers, and note if either needs to change.
- [x] H1 "0.18" no longer applies at ±24.8 days; give the final number.
- [x] S15 in `09` uses bandwidth rows; Donald's chosen full-window values differ and need the
      code updated. List the final numbers beside S15's.
- [x] Which outlets drop under the pre-period outcome and why.
- [x] All numbers confirmed for the talk.
- [x] Slides must include every stage: H1 five, H2 eight, H3 eight, sample bars three. Stage
      numbers changed from the spec; the mapping is in section 2 of the report.
- [x] Slides must include all four sample maps.
- [x] Vote map is labeled by actual vote. Kosovo is not a UN member, so talking points must exclude it.
- [x] Appendix slides include `h3_s4_lowess_present.png`.
- [x] The other chat must use the new colors in anything it draws, including TikZ.
- [x] Deck preamble: `treatyClient` becomes `#8E44AD`.
- [x] Vote map colors changed: against `#4A235A`, abstained `#A569BD`.
- [x] Floor figure: non-treaty independent now matches H2's independent blue.

## Spec disagreement log

Feeds the Phase 7 report.

| # | Spec location | Spec says | Actual | Resolution |
|---|---|---|---|---|
| 1 | Figure 1 | Six treaty clients + "remaining five of the eleven" | Corpus has 4 treaty clients and 7 others (11). Kyrgyzstan and Tajikistan are not in the corpus, so the map shows 13 | Map shows 13 |
| 2 | Figure 7 | Window from Table 1 Model 4 | Model 4 is all-topic, raw score. The deck's -0.184 and the non-military sample are Model 6 | Use Model 6's window |
| 3 | Figures 7-9 | Windows read from "the model object" (variant not named) | Deck estimates match the probabilistic models, not days (H1 -0.184 vs -0.205; H2 +0.222 vs +0.248; H3 -0.38 vs -0.311) | Probabilistic windows, daily points |
| 4 | Figure 7, `h1_s2` title | Straight lines show a 0.18 SD drop | Full-range raw line (days) drops -0.129, about 0.23 SD on the pooled raw SD. 0.18 was Model 6's windowed estimate | Title is Donald's call |
| 5 | Figure 8, `h2_s2` title | State-owned "dropped half as far" | Raw non-NATO, full range: -0.156 vs -0.042, about a quarter. Half holds only for all countries (-0.140 vs -0.070). See final numbers for the new outcome | Non-NATO kept; title is Donald's call |
| 6 | Figure 8 | Rebuild the existing file as Model 6's non-NATO sample | The existing file uses all countries, so this changes the sample, not only the colors | Non-NATO |
| 7 | Figure 7 | "Local linear fits" | Existing figures use unweighted straight-line fits | Plain lines |
| 8 | Figure 5, "61 outlets" | 61 outlets | Data has 62 distinct outlets; 61 after dropping zero-variance `insajder.net`. `balkaninsight.com` spans Kosovo and Serbia, so per-country counts sum to 62 | Exclude; note in table |
| 9 | Figure 11, floor | One group color, `nonTreatyText`, for a two-series figure | Two series in one color can't be told apart | Green for state, H2's blue for independent |
| 10 | Figure 1 | Reuse `region_map.png` extent if suitable | It has no projected CRS and cuts off Kazakhstan | New extent |
| 11 | Figures 2-3 | At least 1600 px wide | Screenshot is 1321 px; `invasion_photo.png` is 1535 px | Upscale screenshot; copy photo |
| 12 | Delivery sections | Output to `presentation/figures/`; scripts `make_*.R` | Folder doesn't exist; Donald chose `figures/presentation/` and one Rmd | Followed Donald |
| 13 | Figure 4 | Uses `ggpattern`; Figure 2 fallback uses `magick` | Neither is installed; the spec allows a line overlay in place of `ggpattern` | Line overlay; install `magick` |
| 14 | Figure 11 list | Lists three appendix regenerations | Older deck source also uses `invasion_on_sentiment_present.png` in the same appendix build; spec doesn't mention it | Recolored and moved |
| 15 | Color names | `indepMedia` = `#3498DB`, `stateMedia` = `#E67E22` | Existing figures use dodgerblue and forestgreen | Use spec values |
| 16 | Figures 7-9 | H1-H3 click-throughs on the raw score | Donald moved the main figures to the pre-period specification; raw versions go to the appendix | Followed Donald |
| 17 | Figure 9 | Treaty line sits above non-treaty, matching the TikZ ghost | True on the raw score (0.025 vs -0.264). On the pre-period outcome both start near zero | Ghost needs redrawing |
| 18 | All file names | Spec names without `_present` | Donald wants `_present` on every file to separate paper and presentation versions | Followed Donald |
| 19 | Figure 1 | Russia west of 95E fully inside the frame | Fitting the Arctic coast forces an 8,500 km frame, with the sample in the bottom third and the Balkans under the legend | East edge at 95E; Russia runs off the top |
| 20 | Figure 1 | Natural Earth boundaries | Natural Earth draws Crimea as Russian | Crimea moved to Ukraine |
| 21 | Figure 9 | `h3_s3` y range "may tighten" | Two low-volume days stretch the axis to about -1.5 and +1.9 | Tightened to +/-1.1; points listed in numbers file |
| 22 | Figure 1 | Place labels with `ggrepel::geom_label_repel` | Installed `ggrepel` draws a border that can't be removed with this `ggplot2`, and fixed positions keep both maps identical | Plain labels with leader lines |
| 23 | Language rule | Legends never say "aligned" | `sensitivity_ovb_csto_present.png` said "Russia-Aligned" | Relabeled in `06a`; figure regenerated |
| 24 | Figure 1 | Four legend swatches, including "Did not vote" | Donald treats Azerbaijan's non-vote as a technical difference | Azerbaijan shown as abstained; three swatches |
| 25 | Color names | `treatyClient` = `#E74C3C` | Red and green are hard to separate under common color blindness | Purple, `#8E44AD`; deck preamble needs updating |
| 27 | Figure 1 | `suppressRed` against, `mLightBrown` abstained, `nonTreaty` at 35% | Same color-blindness concern | Against `#4A235A`, abstained `#A569BD`, `nonTreaty` at 60% |
| 29 | Figure 1 | Legend says "In sample, no treaty with Russia" | Donald wants these countries labeled by how they voted. The UN record shows all voted for, except Kosovo, which is not a UN member | "In sample, voted for"; Kosovo gets "In sample, not a UN member" |
| 30 | Figure 4 | Three stages; Kyrgyzstan and Tajikistan hatched throughout | Donald wants a blank first stage and the hatching on the treaty stage only | Four stages |
| 31 | Figure 9 | Only `h3_s3` y range "may tighten" | Outliers also flatten the full-range stages | All H3 stages and the lowess figure at +/-1.1 |
| 28 | Appendix | No lowess figure | Donald added a non-robust lowess version of `h3_s4` | `h3_s4_lowess_present.png`; slides need it in the appendix |
| 26 | Figures 5, 7-9 | Three stages for H1-H3, two for the sample bars | Donald wants slower builds | H1 five stages, H2 and H3 eight each, bars three; slides need all of them |
