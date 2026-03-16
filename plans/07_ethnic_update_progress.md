# 07 Ethnic Update Progress

## 07C (Probabilistic) — COMPLETE
- [x] Task 1.1: Keep file header, setup, load data — update overview text
- [x] Task 1.2: Keep ethnic subset creation
- [x] Task 1.3: Add Z-score computation to data_ethnic_state
- [x] Task 1.4: Keep visualization
- [x] Task 2.1: High ethnic Russian population RDD (Z-score)
- [x] Task 2.2: Low ethnic Russian population RDD (Z-score)
- [x] Task 3.1: Bandwidth selection (residualized) and interaction model
- [x] Task 4.1: Non-mil subset, recompute Z-score, residualized BW, interaction model
- [x] Task 5.1: Matching and model estimation
- [x] Task 6.1: Keep/update placebo to use sentiment_z
- [x] Task 7.1: Remove old FE models, by-topic, LOO, saturated, tables
- [x] Task 8.1: Rewrite save chunk with only 5 Z-score models

## 07 (Days running variable) — COMPLETE
- [x] Remove local run_wild_bootstrap
- [x] Add Z-score to data_ethnic_state (no /86400 needed)
- [x] Separate RDD models (high/low) with running
- [x] Optimal BW interaction model (residualized on running)
- [x] Non-mil Z-score model
- [x] Matched model (matchit uses running)
- [x] Placebo updated to sentiment_z, running = date_publish - Dec7
- [x] Save chunk: results_ethnic → 07_ethnic_results.rds

## 07A (Continuous running variable) — COMPLETE
- [x] Remove local run_wild_bootstrap
- [x] Add Z-score to data_ethnic_state (running_continuous / 86400)
- [x] Separate RDD models (high/low) with running_continuous
- [x] Optimal BW interaction model (residualized on running_continuous)
- [x] Non-mil Z-score model
- [x] Matched model (matchit uses running, feols uses running_continuous)
- [x] Placebo updated to sentiment_z, running_continuous = date_publish - Dec7
- [x] Save chunk: results_ethnic_cont → 07_ethnic_results_continuous.rds

## 07B (Drop no-time articles) — COMPLETE
- [x] Remove local run_wild_bootstrap
- [x] Add filter(has_time == TRUE) after data load
- [x] Add Z-score to data_ethnic_state (running_continuous / 86400)
- [x] Separate RDD models (high/low) with running_continuous
- [x] Optimal BW interaction model (residualized on running_continuous)
- [x] Non-mil Z-score model
- [x] Matched model (matchit uses running, feols uses running_continuous)
- [x] Placebo updated to sentiment_z, running_continuous = date_publish - Dec7
- [x] Save chunk: results_ethnic_drop → 07_ethnic_results_drop.rds
