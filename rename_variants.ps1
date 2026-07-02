# Rename the 04-08 analysis scripts to the a/b/c/d variant scheme and retire the
# continuous-time variant to scripts\archive\. Plain file moves; Git/GitHub Desktop
# detect them as renames on commit, so history is preserved.
#
# HOW TO RUN: right-click this file in File Explorer -> "Run with PowerShell".
# Then open GitHub Desktop, review the renames, and commit.

Set-Location -Path $PSScriptRoot
New-Item -ItemType Directory -Force -Path "scripts\archive" | Out-Null

$moves = @(
  @("scripts\04C_main_rdd_analysis_prob.Rmd",        "scripts\04a_main_rdd_analysis_prob.Rmd"),
  @("scripts\04_main_rdd_analysis.Rmd",              "scripts\04b_main_rdd_analysis_days.Rmd"),
  @("scripts\04A_main_rdd_analysis_continuous.Rmd",  "scripts\archive\04c_main_rdd_analysis_cont.Rmd"),
  @("scripts\04B_main_rdd_analysis_drop.Rmd",        "scripts\04d_main_rdd_analysis_drop.Rmd"),

  @("scripts\05C_diff_in_disc_analysis_prob.Rmd",        "scripts\05a_diff_in_disc_analysis_prob.Rmd"),
  @("scripts\05_diff_in_disc_analysis.Rmd",              "scripts\05b_diff_in_disc_analysis_days.Rmd"),
  @("scripts\05A_diff_in_disc_analysis_continuous.Rmd",  "scripts\archive\05c_diff_in_disc_analysis_cont.Rmd"),
  @("scripts\05B_diff_in_disc_analysis_drop.Rmd",        "scripts\05d_diff_in_disc_analysis_drop.Rmd"),

  @("scripts\06C_russian_alignment_analysis_prob.Rmd",        "scripts\06a_russian_alignment_analysis_prob.Rmd"),
  @("scripts\06_russian_alignment_analysis.Rmd",              "scripts\06b_russian_alignment_analysis_days.Rmd"),
  @("scripts\06A_russian_alignment_analysis_continuous.Rmd",  "scripts\archive\06c_russian_alignment_analysis_cont.Rmd"),
  @("scripts\06B_russian_alignment_analysis_drop.Rmd",        "scripts\06d_russian_alignment_analysis_drop.Rmd"),

  @("scripts\07C_ethnic_russian_analysis_prob.Rmd",        "scripts\07a_ethnic_russian_analysis_prob.Rmd"),
  @("scripts\07_ethnic_russian_analysis.Rmd",              "scripts\07b_ethnic_russian_analysis_days.Rmd"),
  @("scripts\07A_ethnic_russian_analysis_continuous.Rmd",  "scripts\archive\07c_ethnic_russian_analysis_cont.Rmd"),
  @("scripts\07B_ethnic_russian_analysis_drop.Rmd",        "scripts\07d_ethnic_russian_analysis_drop.Rmd"),

  @("scripts\08a_publication_outputs.Rmd",       "scripts\08a_publication_outputs_prob.Rmd"),
  @("scripts\08c_publication_outputs_cont.Rmd",  "scripts\archive\08c_publication_outputs_cont.Rmd")
)

foreach ($m in $moves) {
  $src = $m[0]; $dst = $m[1]
  if (Test-Path -LiteralPath $src) {
    Move-Item -LiteralPath $src -Destination $dst -Force
    Write-Host ("  moved: {0} -> {1}" -f (Split-Path $src -Leaf), $dst)
  } else {
    Write-Host ("  skip (not found): {0}" -f $src)
  }
}

Write-Host ""
Write-Host "Done. Open GitHub Desktop, review the renames, and commit."
Read-Host "Press Enter to close"
