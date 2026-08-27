# Claude Code Brief — Signaling Gap Revision Empirics (v3)

This repo (`russia_sentiment_paper`) holds the analysis for "The Signaling Gap."
You are producing new empirical objects for a paper revision. The manuscript
lives on Overleaf, not here — you never touch it. Work through the phases below
IN ORDER. Keep this file open as your instruction reference throughout.

## Before anything else

1. Read the project README, `scripts/README.md`, and `scripts/master.Rmd`.
   These are your map. The analysis is split across ~21 files plus master — do
   NOT brute-force through all of them; open only the files each task names,
   and **ask Donald for clarification when uncertain** rather than exploring
   exhaustively.
2. **Write your own `plan.md` at the repo root** before touching anything:
   phases, tasks, per-task status. Update it as you execute — it is your
   running state and the narrative for the commit history.
3. **Treat README claims as claims, not facts.** The READMEs partly describe
   work from a prior session and contain stale references (files were renamed:
   an old "C" suffix used to mean the probabilistic variant; a third variant
   existed; the current scheme is `a` = probabilistic [PRIMARY], `b` = day,
   `d` = drop-no-time, with retired continuous-time scripts in
   `scripts/archive/`). Verify every documented object against code and disk
   before relying on it.

## Global conventions

- **Prob-only.** All new work is built in the `a` (probabilistic) variant
  files ONLY, following the precedent of the bandwidth-sensitivity script. Do
  NOT propagate new chunks to `b`/`d` files.
- **Read specifications from code, never assume.** Sample definitions vary by
  object (some figures/tables use non-military samples — note `_non_mil`
  filenames; the decomposition table is state-owned/non-NATO/non-military).
  Before running any variant of an existing object, print the exact sample
  filter, outcome construction, and FE structure of the object you are
  mirroring, and record it in plan.md.
- **Reuse existing conventions.** Output subfolders (`figures/`,
  `figures/heterogeneity/prob/`, `figures/tables/prob/`,
  `data/intermediate/`), file-suffix patterns, figure theme (dashed Feb-24
  line), modelsummary styling, `here::here()`, `set.seed(3184)`. Create no new
  conventions.
- **Figures at DATE granularity** (paper convention), even where estimation is
  date-time.
- **Labels.** In all newly generated reader-facing table/figure text, the
  group label is **"Russia-aligned"**, never "CSTO"/"Non-CSTO". Internal
  variable names stay as they are.
- **Commits.** One commit per completed phase/task, descriptive message
  (e.g., `Task E: total-effect models + table_s14`). Donald pushes. Never
  bundle tasks in one commit.
- **Subagents.** Parallelize across independent files (04a vs 05a vs 06a work;
  Phase-0 audits). SERIALIZE anything touching the same file. The publication
  script (09a after renaming) is touched once per task, by you (coordinator),
  at task close, then commit.
- **R execution.** Historically unreliable in this environment. Write all code
  so every output — including every printed summary, as text/CSV — saves to
  the established locations. Attempt execution; if it fails, deliver
  ready-to-run code registered in the right place and tell Donald exactly what
  to run manually so outputs land where they belong.
- **NEVER render `master.Rmd` to get results** — the full pipeline takes ~4
  hours and re-runs steps 01–03, which exist only for replication. Steps 01–03
  save `.rds` files to `data/intermediate/`; load those, never rebuild them.
  Run ONLY the specific script(s) a task needs (prob files, targeted). Before
  attempting any execution, check that `data/intermediate/02_*.rds` exist in
  this clone — the raw CSVs are Dropbox-only and absent from git, so if the
  intermediates are also absent, code-only delivery with manual-run
  instructions is the expected path, not a failure.
- **Honest failure.** If a task isn't working (see Task C especially), stop,
  revert to the last commit, and report — never leave a half-done state or
  deliver something that "mostly" works.

## PHASE 0 — Audit (report in plan.md before any edits)

Verify and reconcile; no analysis changes in this phase.

- **A1. Pre-trend figures.** READMEs claim `pretrend_by_country_aligned.png`
  and `_dec.png` are built in "06C_russian_alignment_analysis_prob.Rmd"
  (stale name). Find the chunks in the current file set. Confirm the figures
  on disk match the documented spec (state-owned, one panel per Russia-aligned
  country — Armenia, Azerbaijan, Belarus, Kazakhstan; Ukraine excluded
  everywhere — Dec 7 and Feb 24 markers, pre-invasion linear fit, the two
  window start dates). Confirm the per-country pre-invasion slope printout
  chunk exists; make it also write to a text file.
- **A2. Aligned placebo objects.** READMEs claim `placebo_aligned_models`
  (per-country Dec 7 2021 placebo RDDs, state-owned non-military, rdrobust,
  MSE-optimal bandwidth, z-scored outcome, unclustered HC) is serialized into
  `06_alignment_results_prob.rds`. The `table_s13_placebo_aligned` chunk
  EXISTS in the publication script (08a → 09a after Phase 1) — the code was
  written but **never run**, so no `.tex` is on disk. Verify the chunk matches
  the documented spec; producing the table is then just a targeted run (or
  manual-run instructions).
- **A3. Pooled aligned-group placebo.** Donald believes a POOLED (all four
  aligned countries together, state-owned) Dec 7 placebo may already exist —
  possibly in the bandwidth-sensitivity script. Search for it. Its existence
  determines Task B's scope.
- **A4. Stale references.** List every stale file/chunk reference in both
  READMEs (old "C" naming, renamed variants) for correction in Phase 1.
- **A5. Canonical figure builders.** The three discontinuity PNGs the paper
  uses (`invasion_on_sentiment_non_mil.png`, `invasion_discs_non_mil.png`,
  `state_align_discs.png`) come from the **`b` (day) variants** — day grouping
  is what keeps the scatter legible — NOT the `a` files. Confirm which chunk
  in 04b/05b/06b writes each exact path, and how the variants avoid
  overwriting each other's figure outputs. This sets Task C's targets.

Report all findings in plan.md, flag anything surprising to Donald, then
proceed.

## PHASE 1 — Renumber + documentation fix (one commit)

- Rename `08{a,b,d}_publication_outputs_*.Rmd` → `09{a,b,d}_...` and
  `09_bandwidth_sensitivity.Rmd` → `08_bandwidth_sensitivity.Rmd` (bandwidth
  reads from `02_*.rds`, so it runs before publication; verify no 04–07
  dependency before committing).
- Update `master.Rmd` render order, both READMEs (including the stale
  references from A4 and correcting any documented-but-nonexistent objects
  found in Phase 0), and any internal cross-references.

## PHASE 2 — Additions (prob-only; one commit per task; 09a touched once per task)

**TASK B — Aligned-group placebo table (scope set by A2/A3).**
If a pooled aligned-group Dec 7 placebo exists (A3): pull it into 09a as a
table alongside the per-country results. If not: build it in 06a mirroring the
main placebo's estimation exactly (state-owned, Russia-aligned pooled, Dec 7
2021 cutoff), then the 09a table. If the s13 per-country table chunk is
genuinely absent (A2), create it per the README's documented spec. Deliverable:
`.tex` in `figures/tables/prob/`.

**TASK D — Country-level clustering check (H2/H3 RDIDs).**
Re-run inference for the H2 and H3 RDID estimates clustered at the COUNTRY
level through the existing WCR bootstrap machinery (Webb six-point weights;
H2 ≈ 11 country clusters, H3 = 8). Point estimates must be IDENTICAL to the
headline (clustering changes inference only) — verify this explicitly; any
divergence means the spec or sample silently changed and must be flagged, not
papered over. Deliver a side-by-side: estimate, source-level WCR p/CI,
country-level WCR p/CI, cluster counts — printed AND saved to a text/CSV in
the established output location. ⚠ Known risk: the WCR machinery historically
conflicted with one of the packages in this stack (which one is not
remembered). Timebox this; if you hit the incompatibility, report the blocker
precisely rather than engineering around it.

**TASK E — Total-effect columns (new estimand; appendix).**
For H1 (04a) and the H2/H3 RDIDs (05a/06a): clone the headline specification,
REMOVE topic fixed effects, use ALL articles including military, z-scored
outcome, same bandwidth procedure and source clustering. (For the RDIDs this
is "Model 5 minus topic FE" — locate Model 5's exact definition in code
first, per the read-the-spec convention.) New model objects in 04a/05a/06a;
new appendix table chunk `table_s14` in 09a, appendix-styled. Also save a
printed side-by-side comparison (total-effect vs. headline: estimates, SEs, N)
to text/CSV.

**TASK F — Floor side-by-side figure (appendix).**
Locate the chunk that builds `invasion_discs_graph_neutral.png`; build the new
figure beside it. Content: neutral-state STATE-OWNED vs. neutral-state
INDEPENDENT media, pre- vs. post-invasion mean sentiment, designed so starting
levels AND drop magnitudes are both unmistakable at a glance (side-by-side
panels or grouped pre/post means — your judgment; existing theme; date
granularity). Purpose: show the neutral state-media null is not a
floor/measurement artifact.

**TASK G — Pre-period adjustment diagnostics (`10_preperiod_diagnostics.Rmd`).**
New standalone script, built by COPYING the relevant machinery from
04a/05a/06a — do not write new estimation code from scratch; the custom
machinery in those files (especially 06a) is the point. Prob data only. Do NOT
register in master.Rmd yet (Donald will after reviewing output). Contents:
(i) topic adjustment fixed at pre-invasion values — demean sentiment by
PRE-period topic means, re-run the H1/H2/H3 headline specs on the demediated
outcome with topic FE removed; (ii) z-score variant — re-standardize using
PRE-invasion source means/SDs only, re-run headline specs; (iii) diagnostic —
pre-period topic means vs. pooled topic-FE coefficients, showing which topics'
mappings move across the cutoff. All comparisons vs. headline estimates,
printed AND saved to text/CSV. These are diagnostics for the authors, not
paper outputs.

**TASK C — Direct figure labels (OPTIONAL, LAST; the one exception to
prob-only).**
The three canonical discontinuity plots are built in the **`b` (day) variant**
files (per A5) — edit those chunks: series names labeled directly on the
figure instead of a legend, existing theme. ⚠ This has failed
repeatedly before (both manually and in a prior Claude Code attempt). Write to
NEW suffixed filenames — NEVER overwrite the canonical PNGs. Self-assess
honestly: if the result is not clearly good, delete the outputs, revert, and
say so. A skipped Task C is a fine outcome.

## PHASE 3 — DEFERRED: do NOT execute

For context only (it may inform how you write Phase 2, e.g., don't invest in
b/d files): a future run may retire the full `b`/`d` clone scripts to
`scripts/archive/` and replace them with thin typology-robustness scripts that
reproduce only the main results tables under each alternative typology, with
corresponding slimming of the publication scripts. Flag anything you notice
that bears on this in plan.md; execute none of it.

## Output manifest (Phase 2)

- `.tex`: aligned placebo table(s) (B); `table_s14` total-effect (E) — in
  `figures/tables/prob/`.
- Figures: floor side-by-side (F); optionally relabeled discontinuity plots
  under new filenames (C).
- Text/CSV summaries in established output locations: pre-invasion slopes
  (A1); pooled + per-country placebo estimates, CI, p, bandwidth, N (B);
  clustering side-by-side (D); total-effect vs. headline comparison (E);
  pre-period-variant comparisons + topic-mapping diagnostic (G).
- `plan.md` at repo root, current at every commit.
