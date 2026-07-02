@echo off
cd /d "%~dp0"

if not exist "scripts\archive" mkdir "scripts\archive"

echo Renaming 04 (Main RDD)...
if exist "scripts\04C_main_rdd_analysis_prob.Rmd"       move "scripts\04C_main_rdd_analysis_prob.Rmd"       "scripts\04a_main_rdd_analysis_prob.Rmd"
if exist "scripts\04_main_rdd_analysis.Rmd"             move "scripts\04_main_rdd_analysis.Rmd"             "scripts\04b_main_rdd_analysis_days.Rmd"
if exist "scripts\04A_main_rdd_analysis_continuous.Rmd" move "scripts\04A_main_rdd_analysis_continuous.Rmd" "scripts\archive\04c_main_rdd_analysis_cont.Rmd"
if exist "scripts\04B_main_rdd_analysis_drop.Rmd"       move "scripts\04B_main_rdd_analysis_drop.Rmd"       "scripts\04d_main_rdd_analysis_drop.Rmd"

echo Renaming 05 (Diff-in-Disc)...
if exist "scripts\05C_diff_in_disc_analysis_prob.Rmd"       move "scripts\05C_diff_in_disc_analysis_prob.Rmd"       "scripts\05a_diff_in_disc_analysis_prob.Rmd"
if exist "scripts\05_diff_in_disc_analysis.Rmd"             move "scripts\05_diff_in_disc_analysis.Rmd"             "scripts\05b_diff_in_disc_analysis_days.Rmd"
if exist "scripts\05A_diff_in_disc_analysis_continuous.Rmd" move "scripts\05A_diff_in_disc_analysis_continuous.Rmd" "scripts\archive\05c_diff_in_disc_analysis_cont.Rmd"
if exist "scripts\05B_diff_in_disc_analysis_drop.Rmd"       move "scripts\05B_diff_in_disc_analysis_drop.Rmd"       "scripts\05d_diff_in_disc_analysis_drop.Rmd"

echo Renaming 06 (Russian Alignment)...
if exist "scripts\06C_russian_alignment_analysis_prob.Rmd"       move "scripts\06C_russian_alignment_analysis_prob.Rmd"       "scripts\06a_russian_alignment_analysis_prob.Rmd"
if exist "scripts\06_russian_alignment_analysis.Rmd"             move "scripts\06_russian_alignment_analysis.Rmd"             "scripts\06b_russian_alignment_analysis_days.Rmd"
if exist "scripts\06A_russian_alignment_analysis_continuous.Rmd" move "scripts\06A_russian_alignment_analysis_continuous.Rmd" "scripts\archive\06c_russian_alignment_analysis_cont.Rmd"
if exist "scripts\06B_russian_alignment_analysis_drop.Rmd"       move "scripts\06B_russian_alignment_analysis_drop.Rmd"       "scripts\06d_russian_alignment_analysis_drop.Rmd"

echo Renaming 07 (Ethnic Russian)...
if exist "scripts\07C_ethnic_russian_analysis_prob.Rmd"       move "scripts\07C_ethnic_russian_analysis_prob.Rmd"       "scripts\07a_ethnic_russian_analysis_prob.Rmd"
if exist "scripts\07_ethnic_russian_analysis.Rmd"             move "scripts\07_ethnic_russian_analysis.Rmd"             "scripts\07b_ethnic_russian_analysis_days.Rmd"
if exist "scripts\07A_ethnic_russian_analysis_continuous.Rmd" move "scripts\07A_ethnic_russian_analysis_continuous.Rmd" "scripts\archive\07c_ethnic_russian_analysis_cont.Rmd"
if exist "scripts\07B_ethnic_russian_analysis_drop.Rmd"       move "scripts\07B_ethnic_russian_analysis_drop.Rmd"       "scripts\07d_ethnic_russian_analysis_drop.Rmd"

echo Renaming 08 (Publication Outputs)...
if exist "scripts\08a_publication_outputs.Rmd"      move "scripts\08a_publication_outputs.Rmd"      "scripts\08a_publication_outputs_prob.Rmd"
if exist "scripts\08c_publication_outputs_cont.Rmd" move "scripts\08c_publication_outputs_cont.Rmd" "scripts\archive\08c_publication_outputs_cont.Rmd"

echo.
echo Done. Open GitHub Desktop, review the renames, and commit.
echo.
pause
