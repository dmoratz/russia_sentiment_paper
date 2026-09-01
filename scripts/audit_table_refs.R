# Cross-reference closure test for the manuscript's table references.
#
# Extracts every \ref / \autoref / \Cref / \hyperref target from the manuscript
# files, and every \label from those files plus the generated table .tex, then
# reports the unresolved set -- references with no matching label. That set must
# be empty.
#
# The manuscript lives on Overleaf, not in this repo, so the two .tex files have
# to be supplied. Nothing here writes to them; the script only reads.
#
# Usage, from the repo root:
#   Rscript scripts/audit_table_refs.R <main.tex> <russia_appendix.tex> [tables_dir]
#
# tables_dir defaults to figures/tables/prob.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  cat("Usage: Rscript scripts/audit_table_refs.R <main.tex> <appendix.tex> [tables_dir]\n")
  quit(status = 2L)
}
manuscript <- args[1:2]
tables_dir <- if (length(args) >= 3) args[3] else file.path("figures", "tables", "prob")

missing <- manuscript[!file.exists(manuscript)]
if (length(missing)) {
  cat("Manuscript file(s) not found:\n"); cat(paste0("  ", missing, collapse = "\n"), "\n")
  quit(status = 2L)
}

read_all <- function(p) paste(readLines(p, warn = FALSE), collapse = "\n")

# --- every reference target in the manuscript --------------------------------
# Covers \ref, \autoref, \cref, \Cref, \pageref, \eqref, \nameref, \fullref --
# anything ending in "ref" and taking a brace argument -- plus \hyperref[...].
extract_targets <- function(txt) {
  brace <- regmatches(txt, gregexpr("\\\\[A-Za-z]*ref\\*?\\{[^}]*\\}", txt, perl = TRUE))[[1]]
  brace <- sub("\\}$", "", sub("^\\\\[A-Za-z]*ref\\*?\\{", "", brace))
  bracket <- regmatches(txt, gregexpr("\\\\hyperref\\[[^]]*\\]", txt, perl = TRUE))[[1]]
  bracket <- sub("\\]$", "", sub("^\\\\hyperref\\[", "", bracket))
  # \cref{a,b} can carry several targets in one call
  unlist(strsplit(c(brace, bracket), "\\s*,\\s*"))
}
refs <- unlist(lapply(manuscript, function(p) extract_targets(read_all(p))))
refs <- trimws(refs)
refs <- unique(refs[nzchar(refs)])
refs_tab <- sort(refs[grepl("^tab", refs)])

# --- every label, manuscript plus generated tables ----------------------------
tex_files <- c(manuscript,
               list.files(tables_dir, pattern = "\\.tex$", full.names = TRUE))
labels <- unlist(lapply(tex_files, function(p) {
  txt <- read_all(p)
  hits <- regmatches(txt, gregexpr("\\\\label\\{[^}]*\\}", txt))[[1]]
  sub("^\\\\label\\{(.*)\\}$", "\\1", hits)
}))
labels <- unique(trimws(labels))
labels_tab <- sort(labels[grepl("^tab", labels)])

# --- report -------------------------------------------------------------------
cat("=== Table cross-reference audit ===\n")
cat("manuscript :", paste(manuscript, collapse = ", "), "\n")
cat("tables dir :", tables_dir, "\n\n")
cat(sprintf("table references found : %d\n", length(refs_tab)))
cat(sprintf("table labels found     : %d\n\n", length(labels_tab)))

unresolved <- setdiff(refs_tab, labels_tab)
orphans    <- setdiff(labels_tab, refs_tab)

if (length(unresolved)) {
  cat("UNRESOLVED -- referenced but no label defines them:\n")
  cat(paste0("  ", unresolved, collapse = "\n"), "\n\n")
} else {
  cat("UNRESOLVED: none. Every table reference resolves.\n\n")
}

if (length(orphans)) {
  cat("Labels never referenced (informational, not a failure):\n")
  cat(paste0("  ", orphans, collapse = "\n"), "\n\n")
}

# duplicate labels across generated tables would silently break numbering
dupe_src <- unlist(lapply(list.files(tables_dir, pattern = "\\.tex$", full.names = TRUE),
  function(p) {
    txt <- read_all(p)
    hits <- regmatches(txt, gregexpr("\\\\label\\{[^}]*\\}", txt))[[1]]
    sub("^\\\\label\\{(.*)\\}$", "\\1", hits)
  }))
dupes <- names(which(table(dupe_src) > 1))
if (length(dupes)) {
  cat("DUPLICATE labels among generated tables:\n")
  cat(paste0("  ", dupes, collapse = "\n"), "\n\n")
} else {
  cat("No duplicate labels among generated tables.\n\n")
}

fail <- length(unresolved) > 0 || length(dupes) > 0
cat(if (fail) "AUDIT FAILED\n" else "AUDIT PASSED\n")
quit(status = if (fail) 1L else 0L)
