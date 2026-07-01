# Plan: Variant parity (Task 1) + file reorganization (Task 2)

**Author:** Claude (for Donald)
**Date:** 2026-07-01
**Status:** DRAFT FOR REVIEW — no files will be renamed/moved or content-edited until approved.

Two jobs:

1. **Parity** — bring the non-prob variants of scripts 04–07 (and the 08 tables) up to the
   probabilistic ("prob") track, which is now the primary analysis. End state: within each
   family the files are identical except for (a) the running variable / input data and
   (b) figure/table labels and output paths.
2. **Reorg** — rename/reorder the 04–07 files to match the 08 lettering (a=prob, b=days,
   c=cont, d=drop), move the `_cont` versions to an archive folder, and update `master.Rmd`
   and both READMEs.

---

## 0. First: what "git is corrupted" meant

Your local repo is fine. The corruption is only in **this sandbox's mirrored view** of the
Dropbox-synced folder: one loose object (`.git/objects/62/e83d…`) reads as truncated here and
`.git/index.lock` is permission-locked in the mount, so `git status` / `git diff` / `git mv`
fail *in the sandbox*. On your machine git works normally. Practical implication: I can edit
file **contents** reliably (those writes sync back to Dropbox), but I should not run git
operations here. See §5 for how we handle the renames.

---

## 1. The four data "treatments" and the current naming

| Treatment | Running variable | Input data | 04–07 file | 08 file | Fig path / table subdir |
|-----------|------------------|-----------|------------|---------|--------------------------|
| **prob** (primary) | `running_probabilistic` (secs/86400) | full data, KDE-imputed times | `..C_..._prob` | `08a` | `*_PROB` / `prob` |
| **days** | `running` (integer days) | full data | `.._...` (no letter) | `08b` | `*_DAYS` / `days` |
| **cont** | `running_continuous` | full data, real times | `..A_..._continuous` | `08c` | `*_CONT` / `continuous` |
| **drop** | `running_continuous` | `filter(has_time == TRUE)` | `..B_..._drop` | `08d` | `*_DROP` / `drop` |

So 04–07 currently order as days→cont→drop→prob, while 08 already orders prob→days→cont→drop.
The reorg makes 04–07 match 08.

---

## 2. Reorg (Task 2): rename map — "Mirror 08: a/b/c/d"

Proposed renames (prob=a, days=b, cont=c→archive, drop=d):

| Current | New |
|---------|-----|
| `04C_main_rdd_analysis_prob.Rmd` | `04a_main_rdd_analysis_prob.Rmd` |
| `04_main_rdd_analysis.Rmd` | `04b_main_rdd_analysis_days.Rmd` |
| `04A_main_rdd_analysis_continuous.Rmd` | `archive/04c_main_rdd_analysis_cont.Rmd` |
| `04B_main_rdd_analysis_drop.Rmd` | `04d_main_rdd_analysis_drop.Rmd` |
| `05C_diff_in_disc_analysis_prob.Rmd` | `05a_diff_in_disc_analysis_prob.Rmd` |
| `05_diff_in_disc_analysis.Rmd` | `05b_diff_in_disc_analysis_days.Rmd` |
| `05A_diff_in_disc_analysis_continuous.Rmd` | `archive/05c_diff_in_disc_analysis_cont.Rmd` |
| `05B_diff_in_disc_analysis_drop.Rmd` | `05d_diff_in_disc_analysis_drop.Rmd` |
| `06C_russian_alignment_analysis_prob.Rmd` | `06a_russian_alignment_analysis_prob.Rmd` |
| `06_russian_alignment_analysis.Rmd` | `06b_russian_alignment_analysis_days.Rmd` |
| `06A_russian_alignment_analysis_continuous.Rmd` | `archive/06c_russian_alignment_analysis_cont.Rmd` |
| `06B_russian_alignment_analysis_drop.Rmd` | `06d_russian_alignment_analysis_drop.Rmd` |
| `07C_ethnic_russian_analysis_prob.Rmd` | `07a_ethnic_russian_analysis_prob.Rmd` |
| `07_ethnic_russian_analysis.Rmd` | `07b_ethnic_russian_analysis_days.Rmd` |
| `07A_ethnic_russian_analysis_continuous.Rmd` | `archive/07c_ethnic_russian_analysis_cont.Rmd` |
| `07B_ethnic_russian_analysis_drop.Rmd` | `07d_ethnic_russian_analysis_drop.Rmd` |
| `08c_publication_outputs_cont.Rmd` | `archive/08c_publication_outputs_cont.Rmd` |
| `08a`, `08b`, `08d` | unchanged |

Notes / small open choices:
- I kept the descriptive suffix on the prob file (`04a_..._prob`). 08's prob file is just
  `08a_publication_outputs.Rmd` (no `_prob`). If you want strict consistency I can either drop
  `_prob` from the new a-files or rename `08a → 08a_publication_outputs_prob.Rmd`. **Minor;
  tell me your preference.**
- Renaming a `.Rmd` does **not** require touching its internal code: `fig.path`, `saveRDS`,
  and `readRDS` use the `FIGURES_*` / rds-name strings, not the filename. So rename is
  orthogonal to content (§4 confirms artifact names stay put).
- Scripts do not `source()` each other (only `00_setup.R`), so the only cross-reference to
  update is `master.Rmd` (§6).

---

## 3. Parity (Task 1): per-family comparison of prob vs the other variants

I compared section structure, chunk counts, and presence of each major analysis block. The
verdict differs sharply by family. **"Port"** below = copy the prob-track block into
days/drop, adapting the running-variable arithmetic and labels/paths.

### 04 — Main RDD (H1). *Effort: low.* Near-clones already.
- Prob changed the FE in two models: prob uses **Topic** FE where days/drop use **Country**
  FE ("Model 2: With Country FE" → "With Topic FE"; likewise Model 3). Full parity = days &
  drop adopt prob's topic-FE spec. **This changes their Model 2/3 results** — confirm intended.
- Days has an extra "Main RDD Plot for Presentations" chunk not in prob. Candidate to drop
  (or port into prob). Your call.
- Otherwise: mechanical running-variable + label/path swap.

### 05 — Diff-in-Disc (H2). *Effort: moderate.* Mostly parallel; some reorg.
- Days/drop open with "Main Diff-in-Disc" + "Neutral Only Diff-in-Disc" sections; prob
  replaces these with "State-Owned Media Only (RDD)" first and adds a "Visualization: Main
  Diff-in-Disc Plot" section. Full parity = adopt prob's ordering/sections.
- All variants (incl. prob) still build **inline summary tables** ("Table 2 / 2I …") *and*
  08x builds publication tables — duplicated. See the cross-cutting decision below.
- `master.Rmd`'s own note flags "05 needs rework to match 05C"; the structural gap is smaller
  than that implies, but the section reorg is real.

### 06 — Alignment (H3a). *Effort: high.* The genuinely divergent family.
- **Prob-only (must port to days & drop):**
  - "Pre-Trend Diagnostic: State Media in Russia-Aligned Countries" (the two new figures +
    per-country slopes).
  - "Placebo Test … (Aligned State Media, by Country)" (the four per-country placebos).
  - "Pooled Fully Saturated Regression" + "Mini-Regressions Approach" (decomposition;
    serialized as `decomposition` in the results list).
- **Days/drop-only (NOT in prob — your anticipated case; decide keep/port/drop):**
  - "State Media by Country and Alliance" section (present in days & drop, absent in prob).
  - Inline "Summary Table (Table 3 / 3F)" + "By Topic" summary-table sections.
  - Days-only "Non-Parametric Saturation Check"; drop has extra `matchit`/`ggridges` blocks.
- Adapting the ported blocks needs per-variant time arithmetic (see "idioms" below).

### 07 — Ethnic (H3b). *Effort: trivial.* Identical structure (15 chunks each). Pure
running-variable + label/path swap. No new content to port.

### 08 — Publication tables. *Effort: low-moderate.*
- 08b/08c/08d are otherwise identical to the pre-edit 08a. Only the prob file (08a) has the
  new `table_s13_placebo_aligned` + the `placebo_aligned_models` check line.
- Port `table_s13` (and the check line, `fix_gt_caption` entry, summary line) into **08b
  (days)** and **08d (drop)**. This **requires** the per-country placebo models to exist in
  their input rds — i.e., 06b/06d must be brought to parity first (dependency).
- 08c (cont) is archived → not updated.

### Per-variant "idioms" the ported blocks must respect (not a blind find/replace)
- Running-variable name: `running_probabilistic` → `running` (days) / `running_continuous`
  (drop). Prob divides seconds by 86400; **days uses integer `running` directly** (no /86400).
- Cutoff/time math: prob uses `date_publish_probabilistic` + `difftime(...,"secs")/86400`;
  days uses `date_publish` (a `Date`) with `as.numeric(date_publish - as.Date("2021-12-07"))`;
  drop uses `date_publish_continuous` on the `has_time == TRUE` subset.
- Pre-trend figure is calendar-date based, so it is **identical across variants** except the
  drop version sits on the `has_time` subset (fewer points) and the fig path/object names.
- Paths/labels: `FIGURES_*_PROB` → `_DAYS` / `_DROP`; `saveRDS(... _prob.rds)` → `.rds` /
  `_drop.rds`; chunk-label suffix `-prob` → `-days` / `-drop`; titles "(Probabilistic)" →
  "(Day)" / "(Drop No-Time)".

### Cross-cutting decision (please rule): inline summary tables in the analysis files
The days/drop 04–06 files build their own "Table 2/3" summary tables inline, while the prob
files largely delegate tables to 08x. Options: (a) **strip** the inline tables from days/drop
for true parity with prob (08x is the single table source); (b) **keep** them everywhere and
add matching inline tables to prob; (c) leave as-is. My recommendation: **(a)**, so 08x is the
one place tables are built. This is the biggest single lever on how "identical" the files end up.

---

## 4. Downstream impact of renaming **artifacts** (Q3) — recommendation: DON'T

You asked for a sense of what renaming the *output* names (rds / figure subfolders /
`TABLE_SUBDIR`) — not just the script files — would touch. If we renamed
`prob/days/cont/drop` → `a/b/c/d` everywhere:

- **`00_setup.R`**: rename `FIGURES_RDD_PROB`, `FIGURES_DIFF_DISC_PROB`,
  `FIGURES_HETEROGENEITY_PROB` (and _DAYS/_CONT/_DROP) plus the `dir.create` list.
- **Every 04–07 file**: `fig.path` and every `saveRDS(..., "0X_*_prob.rds")`.
- **Every 08 file**: four `readRDS(... _prob.rds)`, `TABLE_SUBDIR <- "prob"`, and all
  `save_table(..., subdir)` calls.
- **The paper itself**: `main.tex` / appendix `\input` and `\includegraphics` reference
  `figures/tables/prob/table_*.tex` and `figures/.../ *.png`. Renaming artifacts **breaks
  those includes and would force edits to `main.tex`/appendix — which you've asked to leave
  untouched.**
- **`writing/`, `output/`, `figures/tables/*/` on-disk folders**: physical directories would
  need moving; existing generated `.tex`/`.png`/`.rds` would be orphaned until re-run.

**Recommendation:** rename **only the `.Rmd` script prefixes** (§2). Keep the descriptive
artifact names (`prob/days/cont/drop`) so nothing downstream — especially the LaTeX — breaks.
The script letters (a/b/c/d) and the artifact words (prob/days/…) can coexist; the mapping is
documented in `master.Rmd` and the READMEs.

---

## 5. File-move mechanics (Q4)

Given the sandbox git state, cleanest is: **I make all content edits (parity ports,
`master.Rmd`, READMEs) against the current filenames; you perform the renames/moves with
`git mv` locally** (preserves history and rename tracking). I'll hand you a ready-to-paste
`git mv` script matching §2. Alternatively I can do plain `mv` here (no history tracking, and a
small Dropbox-sync-conflict risk). Renames are orthogonal to content (§2), so either order is
safe, but I suggest **content edits first, renames last** to avoid churn.

---

## 6. `master.Rmd` + README updates (part of Task 2)

- **`master.Rmd`**: reorder the render steps to prob → days → drop (drop the cont steps into a
  commented "archived" note or remove), update every `render("…")` filename to the new names,
  the step headers/labels, the timing printouts, the ASCII workflow diagram, and the
  File-Descriptions table. Also delete the stale "Changes to make" note at the top (it's the
  very drift we're resolving).
- **`scripts/README.md`** and **`README.md`**: update the pipeline tables/diagrams to the new
  a/b/c/d naming and the prob-primary ordering; note cont is archived; keep the pre-trend /
  per-country-placebo entries added earlier.

---

## 7. Proposed execution order (after approval)

1. **Confirm decisions** (the four rulings flagged: FE-spec adoption in 04; inline-table
   strip in 05/06; keep/port/drop the days/drop-only 06 blocks; suffix style for a-files).
2. **Parity content edits** on current filenames, family by family, easiest→hardest:
   07 → 04 → 05 → 06, then 08b/08d. Verify each family compiles-clean structurally
   (I can't run R here, so this is a code review + variable/path audit; you run the pipeline).
3. **Renames/moves** (you via `git mv`, or I via `mv`), including cont → `archive/`.
4. **`master.Rmd` + READMEs** updated to the new names/order.
5. **Verification pass**: audit that every file's running variable, `fig.path`, `saveRDS`,
   and (for 08) `readRDS`/`TABLE_SUBDIR` are internally consistent; that no `main.tex`/appendix
   or artifact path changed; and a chunk-label parity check across each family.

---

## 8. Open decisions for you (blocking execution)

- **D1 (04 FE spec):** adopt prob's Topic-FE spec in days & drop Models 2/3 (changing their
  results), or leave their Country-FE spec? 
- **D2 (inline tables):** strip inline summary tables from days/drop analysis files so 08x is
  the sole table source (my rec), keep everywhere, or leave as-is?
- **D3 (06 days/drop-only blocks):** for "State Media by Country and Alliance",
  "Non-Parametric Saturation Check", and the extra drop `matchit`/`ggridges` blocks — drop
  them for parity, or port them **into** prob so all three match?
- **D4 (naming polish):** keep `_prob` suffix on the new a-files, or drop it / add `_prob` to
  08a for strict symmetry?
- **D5 (mechanics):** you run `git mv` from my script (rec), or I `mv` in-sandbox?
- **D6 (cont):** confirm cont is archived **untouched** (no parity work ported to it).
