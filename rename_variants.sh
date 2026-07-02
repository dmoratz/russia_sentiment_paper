#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Rename the 04-08 analysis scripts to the a/b/c/d variant scheme and retire
# the continuous-time variant to scripts/archive/.
#
#   a = _prob  (probabilistic time, PRIMARY)
#   b = _days  (day running variable)
#   c = _cont  (continuous time)  -> ARCHIVED
#   d = _drop  (drop no-time articles)
#
# Uses `git mv` so history is preserved. Run once from the repo root:
#   bash rename_variants.sh
# (On Windows, run it in Git Bash.) Then delete this script if you like.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p scripts/archive

# --- 04: Main RDD (H1) ---
git mv scripts/04C_main_rdd_analysis_prob.Rmd        scripts/04a_main_rdd_analysis_prob.Rmd
git mv scripts/04_main_rdd_analysis.Rmd              scripts/04b_main_rdd_analysis_days.Rmd
git mv scripts/04A_main_rdd_analysis_continuous.Rmd  scripts/archive/04c_main_rdd_analysis_cont.Rmd
git mv scripts/04B_main_rdd_analysis_drop.Rmd        scripts/04d_main_rdd_analysis_drop.Rmd

# --- 05: Diff-in-Disc (H2) ---
git mv scripts/05C_diff_in_disc_analysis_prob.Rmd        scripts/05a_diff_in_disc_analysis_prob.Rmd
git mv scripts/05_diff_in_disc_analysis.Rmd              scripts/05b_diff_in_disc_analysis_days.Rmd
git mv scripts/05A_diff_in_disc_analysis_continuous.Rmd  scripts/archive/05c_diff_in_disc_analysis_cont.Rmd
git mv scripts/05B_diff_in_disc_analysis_drop.Rmd        scripts/05d_diff_in_disc_analysis_drop.Rmd

# --- 06: Russian Alignment (H3a) ---
git mv scripts/06C_russian_alignment_analysis_prob.Rmd        scripts/06a_russian_alignment_analysis_prob.Rmd
git mv scripts/06_russian_alignment_analysis.Rmd              scripts/06b_russian_alignment_analysis_days.Rmd
git mv scripts/06A_russian_alignment_analysis_continuous.Rmd  scripts/archive/06c_russian_alignment_analysis_cont.Rmd
git mv scripts/06B_russian_alignment_analysis_drop.Rmd        scripts/06d_russian_alignment_analysis_drop.Rmd

# --- 07: Ethnic Russian (H3b) ---
git mv scripts/07C_ethnic_russian_analysis_prob.Rmd        scripts/07a_ethnic_russian_analysis_prob.Rmd
git mv scripts/07_ethnic_russian_analysis.Rmd              scripts/07b_ethnic_russian_analysis_days.Rmd
git mv scripts/07A_ethnic_russian_analysis_continuous.Rmd  scripts/archive/07c_ethnic_russian_analysis_cont.Rmd
git mv scripts/07B_ethnic_russian_analysis_drop.Rmd        scripts/07d_ethnic_russian_analysis_drop.Rmd

# --- 08: Publication Outputs (08b/08d keep their names) ---
git mv scripts/08a_publication_outputs.Rmd       scripts/08a_publication_outputs_prob.Rmd
git mv scripts/08c_publication_outputs_cont.Rmd  scripts/archive/08c_publication_outputs_cont.Rmd

echo "Rename complete. Review with: git status"
