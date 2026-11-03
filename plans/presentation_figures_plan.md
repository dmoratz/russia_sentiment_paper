# Presentation Figures Plan

Source spec: `C:\Users\skybl\Downloads\job-talk-figure-specs.md` (Figures 1-11), as changed by
the decisions below.

**How to use this file:** tick a box as soon as its step is done, not in batches, so an
interrupted session can resume from here. Add anything the spec gets wrong to the
disagreement log as it turns up.

**Current status:** approved and in progress. Resume at the first unticked box.

## Ground rules

- **Never push to GitHub.** Donald handles all pushes. Do not commit unless he asks.
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
  hypothesis's sample, NOT the bandwidth rows S15 uses. Donald will update `09` himself.
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
- **Vote map:** 13 countries. Six treaty clients by UN vote; the other seven green.
- **Exclude `insajder.net`** everywhere, for 61 outlets. Note that `balkaninsight.com` spans
  Kosovo and Serbia, so per-country outlet counts sum to 62.
- **Figure 6** uses the non-Ukraine sample.
- **Floor figure:** `nonTreatyText` for state media, `nonTreaty` for independent media.
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

- [ ] Add `FIGURES_PRESENTATION` to `scripts/00_setup.R` and its directory list
- [ ] Install `magick`
- [ ] Create `scripts/12_presentation_figures.Rmd` with outline, `pal` list and shared helpers
- [ ] Remove moved chunks from `04b`, `05b`, `06b`; confirm nothing later depends on them
- [ ] Change the save path in `06a`; copy the existing PNG so the folder is complete
- [ ] Add the new script to `scripts/master.Rmd` and the README script tables

## Phase 2: Maps

- [ ] Shared `countries` frame, projection and extent; Kosovo matched correctly
- [ ] Figure 1: `un_vote_map_present.png`
- [ ] Figure 4: `sample_map_s1_present.png`, `_s2_`, `_s3_`
- [ ] Check at 250 px wide: labels legible, no overlaps, no country clipped

## Phase 3: Descriptive figures

- [ ] Figure 5: `sample_by_country_s1_present.png`, `_s2_`
- [ ] Figure 5: country x ownership Markdown count table
- [ ] Figure 6: `articles_per_day_s1_present.png`, `_s2_`

## Phase 4: Main results

- [ ] Build the pre-period outcome, H1 / H2 / H3 samples, matched rows
- [ ] Check matched main estimates still reproduce (+0.222, -0.380) before using the rows
- [ ] Figure 7: `h1_s1_present.png`, `_s2_`, `_s3_`
- [ ] Figure 8: `h2_s1_present.png`, `_s2_`, `_s3_`
- [ ] Figure 9: `h3_s1_present.png`, `_s2_`, `_s3_`
- [ ] Estimates and bootstrap; R1-R3 numbers
- [ ] Axes identical across the stages that share a range

## Phase 5: Appendix and moved figures

- [ ] `h1_raw_full_present.png`, `h2_raw_full_present.png`, `h3_raw_full_present.png`
- [ ] Figure 10: `pretrend_by_country_treaty_present.png`
- [ ] Figure 11: `invasion_discs_graph_present.png`, `state_align_discs_present.png`
- [ ] Figure 11: `nontreaty_floor_present.png`
- [ ] `invasion_on_sentiment_present.png`, `invasion_on_sentiment_present_nonmil.png`
- [ ] `invasion_discs_graph_present_nonmil.png`, `invasion_discs_graph_present_neutral.png`
- [ ] `state_align_discs_present_nonmil.png`

## Phase 6: Non-R figures

- [ ] Figure 2: `kazahk_media_screenshot_present.png`
- [ ] Figure 3: `invasion_photo_present.png`

## Phase 7: Final checks and report

- [ ] Render the new script from a clean R session
- [ ] View every PNG; confirm banned legend words are gone ("aligned", "neutral", "Russia-aligned")
- [ ] Write `figures/presentation/figure_numbers.md`
- [ ] Write the hand-back report, `plans/presentation_figures_spec_report.md`

### Must appear in the final report

- [ ] TikZ ghost for R3 needs redrawing: both lines now start near zero (log #17).
- [ ] H2 title: "half as far" holds at full range but not in the window; confirm final numbers.
- [ ] H3 titles: double check "Non-Treaty ... Did Not Move" and "Treaty ... Fell" on final
      numbers, and note if either needs to change.
- [ ] H1 "0.18" no longer applies at ±24.8 days; give the final number.
- [ ] S15 in `09` uses bandwidth rows; Donald's chosen full-window values differ and need the
      code updated. List the final numbers beside S15's.
- [ ] Which outlets drop under the pre-period outcome and why.
- [ ] All numbers confirmed for the talk.

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
| 9 | Figure 11, floor | One group color, `nonTreatyText`, for a two-series figure | Two series in one color can't be told apart | Two greens |
| 10 | Figure 1 | Reuse `region_map.png` extent if suitable | It has no projected CRS and cuts off Kazakhstan | New extent |
| 11 | Figures 2-3 | At least 1600 px wide | Screenshot is 1321 px; `invasion_photo.png` is 1535 px | Upscale screenshot; copy photo |
| 12 | Delivery sections | Output to `presentation/figures/`; scripts `make_*.R` | Folder doesn't exist; Donald chose `figures/presentation/` and one Rmd | Followed Donald |
| 13 | Figure 4 | Uses `ggpattern`; Figure 2 fallback uses `magick` | Neither is installed; the spec allows a line overlay in place of `ggpattern` | Line overlay; install `magick` |
| 14 | Figure 11 list | Lists three appendix regenerations | Older deck source also uses `invasion_on_sentiment_present.png` in the same appendix build; spec doesn't mention it | Recolored and moved |
| 15 | Color names | `indepMedia` = `#3498DB`, `stateMedia` = `#E67E22` | Existing figures use dodgerblue and forestgreen | Use spec values |
| 16 | Figures 7-9 | H1-H3 click-throughs on the raw score | Donald moved the main figures to the pre-period specification; raw versions go to the appendix | Followed Donald |
| 17 | Figure 9 | Treaty line sits above non-treaty, matching the TikZ ghost | True on the raw score (0.025 vs -0.264). On the pre-period outcome both start near zero | Ghost needs redrawing |
| 18 | All file names | Spec names without `_present` | Donald wants `_present` on every file to separate paper and presentation versions | Followed Donald |
