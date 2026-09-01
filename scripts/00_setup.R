# =============================================================================
# 00_setup.R
# Shared setup file for Russia Sentiment Analysis Pipeline
# =============================================================================
# This file contains:
# - Package loading
# - Custom functions
# - Global settings
# - Color palettes and themes
# =============================================================================

# -----------------------------------------------------------------------------
# Package Loading
# -----------------------------------------------------------------------------

# Use pacman for efficient package management
if (!require("pacman")) install.packages("pacman")

pacman::p_load(

  # Data manipulation

  tidyverse,
  dplyr,
  tidyr,
  purrr,
  data.table,
  lubridate,
  stringr,
  stringdist,
  readr,
  haven,
  foreign,


  # Visualization
  ggplot2,
  patchwork,
  cowplot,
  grid,
  gridExtra,
  scales,
  ggpubr,
  plotly,

  # Tables
  gt,
  knitr,
  kableExtra,
  modelsummary,
  stargazer,
  texreg,
  pander,

  # Statistical analysis
  estimatr,
  fixest,
  lfe,
  plm,
  sandwich,

  lmtest,
  rdrobust,
  AER,
  VGAM,

  # Other utilities
  here,
  broom,
  zoo,

  # Matching, sensitivity, and bootstrap
  fwildclusterboot,
  MatchIt,
  cobalt,
  rbounds,
  sensemakr,
  ggridges,

  # Spatial and inter-rater reliability
  rnaturalearth,
  rnaturalearthdata,
  sf,
  irr
)

# -----------------------------------------------------------------------------
# Global Settings
# -----------------------------------------------------------------------------

# Set seed for reproducibility.
#
# Two streams have to be seeded, not one. fwildclusterboot >= 0.13 draws its
# bootstrap weights through dqrng rather than base R, so `set.seed()` alone does
# NOT make `boottest()` reproducible: bootstrap p-values drift by a few
# thousandths between sessions (Monte Carlo error). Seeding dqrng
# here makes every wild cluster bootstrap in the pipeline exactly reproducible.
set.seed(3184)
if (requireNamespace("dqrng", quietly = TRUE)) dqrng::dqset.seed(3184)

# Scientific notation threshold
options(scipen = 3, digits = 3)

# Define project paths
PROJECT_ROOT <- here::here()
DATA_RAW <- file.path(PROJECT_ROOT, "data", "raw")
DATA_PROCESSED <- file.path(PROJECT_ROOT, "data", "processed")
DATA_INTERMEDIATE <- file.path(PROJECT_ROOT, "data", "intermediate")
FIGURES_DIR <- file.path(PROJECT_ROOT, "figures")

# Figure subdirectories
FIGURES_TABLES <- file.path(FIGURES_DIR, "tables")
FIGURES_DESCRIPTIVE <- file.path(FIGURES_DIR, "descriptive")
FIGURES_DAG <- file.path(FIGURES_DIR, "dag")
FIGURES_CODING <- file.path(FIGURES_DIR, "coding")

# RDD subdirectories (by analysis variant)
FIGURES_RDD <- file.path(FIGURES_DIR, "rdd")
FIGURES_RDD_DAYS <- file.path(FIGURES_RDD, "days")
FIGURES_RDD_CONT <- file.path(FIGURES_RDD, "continuous")
FIGURES_RDD_DROP <- file.path(FIGURES_RDD, "drop")
FIGURES_RDD_PROB <- file.path(FIGURES_RDD, "prob")

# Diff-in-disc subdirectories (by analysis variant)
FIGURES_DIFF_DISC <- file.path(FIGURES_DIR, "diff_in_disc")
FIGURES_DIFF_DISC_DAYS <- file.path(FIGURES_DIFF_DISC, "days")
FIGURES_DIFF_DISC_CONT <- file.path(FIGURES_DIFF_DISC, "continuous")
FIGURES_DIFF_DISC_DROP <- file.path(FIGURES_DIFF_DISC, "drop")
FIGURES_DIFF_DISC_PROB <- file.path(FIGURES_DIFF_DISC, "prob")

# Heterogeneity subdirectories (by analysis variant)
FIGURES_HETEROGENEITY <- file.path(FIGURES_DIR, "heterogeneity")
FIGURES_HETEROGENEITY_DAYS <- file.path(FIGURES_HETEROGENEITY, "days")
FIGURES_HETEROGENEITY_CONT <- file.path(FIGURES_HETEROGENEITY, "continuous")
FIGURES_HETEROGENEITY_DROP <- file.path(FIGURES_HETEROGENEITY, "drop")
FIGURES_HETEROGENEITY_PROB <- file.path(FIGURES_HETEROGENEITY, "prob")

# Create directories if they don't exist
all_dirs <- c(
  DATA_RAW, DATA_PROCESSED, DATA_INTERMEDIATE, FIGURES_DIR,
  FIGURES_TABLES, FIGURES_DESCRIPTIVE, FIGURES_DAG, FIGURES_CODING,
  FIGURES_RDD, FIGURES_RDD_DAYS, FIGURES_RDD_CONT, FIGURES_RDD_DROP, FIGURES_RDD_PROB,
  FIGURES_DIFF_DISC, FIGURES_DIFF_DISC_DAYS, FIGURES_DIFF_DISC_CONT, FIGURES_DIFF_DISC_DROP, FIGURES_DIFF_DISC_PROB,
  FIGURES_HETEROGENEITY, FIGURES_HETEROGENEITY_DAYS, FIGURES_HETEROGENEITY_CONT, FIGURES_HETEROGENEITY_DROP, FIGURES_HETEROGENEITY_PROB
)
for (d in all_dirs) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# -----------------------------------------------------------------------------
# Custom Functions
# -----------------------------------------------------------------------------

#' Robustly converts a character column to a POSIXct datetime object.
#'
#' Handles two formats: YYYY-MM-DD HH:MM:SS (full time) and YYYY-MM-DD (date only).
#' If the time component is missing, it defaults the time to 12:00:00 (noon).
#'
#' @param date_col A character vector column containing dates.
#' @return A POSIXct date-time vector.
clean_datetime_col <- function(date_col) {
  result <- date_col %>%
    {
      if_else(
        str_length(.) > 10,
        ymd_hms(.),
        ymd(.) + hours(12)
      )
    }
  return(result)
}

#' Create a standardized RDD visualization
#'
#' @param data Data frame with running and sentiment_clean columns
#' @param group_var Variable to group by (quoted)
#' @param title Plot title
#' @param subtitle Plot subtitle
#' @param colors Named vector of colors for groups
#' @return ggplot object
create_rdd_plot <- function(data, group_var, title, subtitle,
                            colors = c("dodgerblue", "red4")) {

  # Aggregate data for points
  agg_data <- data %>%
    group_by(running) %>%
    summarize(
      sentiment_clean = mean(sentiment_clean, na.rm = TRUE),
      num_obs = n(),
      .groups = "drop"
    )

  # Create plot
  p <- data %>%
    mutate(across(all_of(group_var), as.factor)) %>%
    ggplot(aes(x = running, y = sentiment_clean,
               group = .data[[group_var]],
               color = .data[[group_var]])) +
    geom_point(data = agg_data,
               aes(x = running, y = sentiment_clean, size = num_obs),
               alpha = 0.2, inherit.aes = FALSE) +
    geom_smooth(method = "lm") +
    scale_color_manual(values = colors, name = "Post Invasion") +
    scale_size(name = "Observations") +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.7) +
    theme_classic() +
    labs(title = title, subtitle = subtitle,
         x = "Days Pre/Post Invasion", y = "Sentiment")

  return(p)
}

#' Compute standard deviation effect size
#'
#' @param coefficient Model coefficient
#' @param data Data vector to compute SD from
#' @return Effect size in standard deviations
compute_effect_size <- function(coefficient, data) {
  sd_val <- sd(data, na.rm = TRUE)
  return(coefficient / sd_val)
}

#' Print data validation summary
#'
#' @param data Data frame to validate
#' @param stage Character string describing the pipeline stage
validate_data <- function(data, stage = "Unknown") {
  cat("\n")
  cat("=============================================================\n")
  cat("Data Validation:", stage, "\n")
  cat("=============================================================\n")
  cat("Rows:", nrow(data), "\n")
  cat("Columns:", ncol(data), "\n")
  cat("Missing values by column:\n")

  missing <- colSums(is.na(data))
  missing_pct <- round(missing / nrow(data) * 100, 2)
  missing_df <- data.frame(
    Column = names(missing),
    Missing = missing,
    Percent = paste0(missing_pct, "%")
  )
  print(missing_df[missing_df$Missing > 0, ], row.names = FALSE)

  if (sum(missing) == 0) {
    cat("No missing values detected.\n")
  }
  cat("=============================================================\n\n")
}

#' Print session info for reproducibility
print_session_info <- function() {
  cat("\n")
  cat("=============================================================\n")
  cat("SESSION INFO\n")
  cat("=============================================================\n")
  cat("Date:", as.character(Sys.time()), "\n")
  cat("R version:", R.version.string, "\n")
  cat("Platform:", R.version$platform, "\n")
  cat("\nKey packages:\n")

  key_packages <- c("tidyverse", "ggplot2", "fixest", "lfe", "rdrobust",
                    "modelsummary", "gt")
  for (pkg in key_packages) {
    if (pkg %in% rownames(installed.packages())) {
      cat(paste0("  ", pkg, ": ", packageVersion(pkg), "\n"))
    }
  }
  cat("=============================================================\n")
}

# -----------------------------------------------------------------------------
# Color Palettes
# -----------------------------------------------------------------------------

# Main colors for treatment/control
COLORS_TREATMENT <- c("0" = "dodgerblue", "1" = "red4")

# Colors for state/independent media
COLORS_MEDIA <- c(
  "Ind. Pre." = "dodgerblue",
  "State Pre." = "forestgreen",
  "Ind. Post" = "red4",
  "State Post" = "darkorange"
)

# Colors for diff-in-disc plots
COLORS_DISCS <- c("dodgerblue", "forestgreen", "red4", "darkorange")

# -----------------------------------------------------------------------------
# Country/Region Definitions
# -----------------------------------------------------------------------------

# State-owned media sources
STATE_OWNED_SOURCES <- c(

  "zviazda.by", "sb.by", "1lurer.am", "agenda.ge", "azerbaijan-news.az",
"azertag.az", "en.armradio.am", "eng.belta.by", "kazpravda.kz", "ktrk.kg",
  "lajme.rtsh.al", "magyarnemzet.hu", "moldova-suverana.md", "qazaqstan.tv",
  "rtklive.com", "rts.rs", "top-channel.tv", "rthaber.com", "ukrinform.net",
  "uza.uz", "trthaber.com"
)

# Country groupings
CSTO_COUNTRIES <- c("Armenia", "Azerbaijan", "Belarus", "Kazakhstan")
NATO_COUNTRIES <- c("Albania", "Ukraine", "Turkey", "Hungary")
NEUTRAL_COUNTRIES <- c("Georgia", "Moldova", "Kosovo", "Serbia")

# Ethnic Russian population groupings
HIGH_RUSSIAN_POP <- c("Moldova", "Belarus", "Kazakhstan", "Georgia")
LOW_RUSSIAN_POP <- c("Azerbaijan", "Armenia", "Kosovo", "Serbia")

# -----------------------------------------------------------------------------
# Knitr Options (for Rmd files)
# -----------------------------------------------------------------------------

if (requireNamespace("knitr", quietly = TRUE)) {
  knitr::opts_chunk$set(
    echo = TRUE,
    warning = FALSE,
    message = FALSE,
    fig.width = 10,
    fig.height = 6,
    cache = FALSE
  )
  # Note: fig.path is set per-script to direct figures to appropriate subfolders
}

# -----------------------------------------------------------------------------
# modelsummary support for rdrobust objects
# -----------------------------------------------------------------------------

#' Tidy method for rdrobust objects (used by modelsummary)
#' Labels the RD estimate as "treatment" for consistent coef_map usage
tidy.rdrobust <- function(x, ...) {
  ret <- data.frame(
    term = "treatment",
    estimate = x$coef[1],
    std.error = x$se[1],
    statistic = x$z[1],
    p.value = x$pv[1],
    conf.low = x$ci[1, 1],
    conf.high = x$ci[1, 2],
    stringsAsFactors = FALSE
  )
  row.names(ret) <- NULL
  ret
}

#' Glance method for rdrobust objects (used by modelsummary)
glance.rdrobust <- function(x, ...) {
  data.frame(
    nobs = x$N[1] + x$N[2],
    nobs.left = x$N[1],
    nobs.right = x$N[2],
    bandwidth.left = x$bws[1, 1],
    bandwidth.right = x$bws[1, 2]
  )
}

# Wild cluster bootstrap helper (used in 05/06 family).
#
# B = 99999 rather than the more usual 4999. The Monte Carlo SE of a bootstrap
# p-value is sqrt(p(1-p)/B), which is ~0.003 at p = 0.05 with B = 4999 -- large
# enough that a result sitting near the threshold flips its significance star
# between runs. Table 4 Model 4 (p ~ 0.048) did exactly that. At B = 99999 the
# MC SE falls to ~0.0007. The cost is small: bootstrapping is a fraction of the
# runtime of these scripts, and the whole pipeline gains roughly four minutes.
run_wild_bootstrap <- function(model, param, clustid = "source_domain", B = 99999) {
  boot_result <- boottest(
    object = model,
    param = param,
    clustid = clustid,
    B = B,
    impose_null = TRUE,
    bootstrap_type = "fnw11",
    type = "webb"
  )

  list(
    se = boot_result$point_estimate / boot_result$t_stat,
    p_val = boot_result$p_val,
    ci_lower = boot_result$conf_int[1],
    ci_upper = boot_result$conf_int[2],
    t_stat = boot_result$teststat
  )
}

#' Compare WCR inference across two clustering levels
#'
#' Re-runs the wild cluster restricted bootstrap on a single fitted model at two
#' different clustering levels and returns both side by side. Clustering changes
#' inference only, so the point estimate is shared by construction and is
#' returned once.
#'
#' Note on empty factor levels: boottest() errors with "length(g) must match
#' length(x)" if the clustering variable is a factor carrying levels with no
#' observations. Sub-samples built without droplevels() hit this. Pass a model
#' fitted on droplevels(data); dropping unused levels cannot move the estimate
#' when the cluster variable is not in the formula or the fixed effects.
#'
#' @param model Fitted fixest model
#' @param param Coefficient name to test (e.g. "treatment:csto")
#' @param label Short identifier for the model, used in the returned row
#' @param levels Character vector of two clustering variables
#' @param B Bootstrap replications (default 99999, matching run_wild_bootstrap)
#' @return One-row tibble: estimate, then p/CI/cluster count at each level
compare_cluster_levels <- function(model, param, label,
                                   levels = c("source_domain", "country"),
                                   B = 99999) {
  one <- function(clustid) {
    tryCatch({
      r <- boottest(object = model, param = param, clustid = clustid, B = B,
                    impose_null = TRUE, bootstrap_type = "fnw11", type = "webb")
      list(se = unname(r$point_estimate / r$t_stat), p_val = unname(r$p_val),
           ci_lower = r$conf_int[1], ci_upper = r$conf_int[2],
           n_clusters = unname(r$N_G), ok = TRUE, err = NA_character_)
    }, error = function(e) {
      list(se = NA_real_, p_val = NA_real_, ci_lower = NA_real_, ci_upper = NA_real_,
           n_clusters = NA_integer_, ok = FALSE, err = conditionMessage(e))
    })
  }

  a <- one(levels[1])
  b <- one(levels[2])

  # Computed before the tibble() call: the 'model' column below would otherwise
  # shadow the 'model' argument under tibble's sequential data masking.
  est <- unname(coef(model)[param])
  n   <- nobs(model)

  tibble::tibble(
    model    = label,
    param    = param,
    estimate = est,
    n_obs    = n,
    !!paste0(levels[1], "_clusters") := a$n_clusters,
    !!paste0(levels[1], "_se")       := a$se,
    !!paste0(levels[1], "_p")        := a$p_val,
    !!paste0(levels[1], "_ci_lower") := a$ci_lower,
    !!paste0(levels[1], "_ci_upper") := a$ci_upper,
    !!paste0(levels[2], "_clusters") := b$n_clusters,
    !!paste0(levels[2], "_se")       := b$se,
    !!paste0(levels[2], "_p")        := b$p_val,
    !!paste0(levels[2], "_ci_lower") := b$ci_lower,
    !!paste0(levels[2], "_ci_upper") := b$ci_upper,
    boot_ok  = a$ok && b$ok,
    boot_err = paste(na.omit(c(a$err, b$err)), collapse = "; ")
  )
}

#' Anchor points for labelling regression series directly on a plot
#'
#' Returns one row per series giving the coordinates at which to draw a direct
#' label instead of relying on a colour legend. The anchor is the fitted value
#' of the same simple linear fit `geom_smooth(method = "lm")` draws, evaluated at
#' the OUTER end of that series' own x range: pre-invasion series run leftward,
#' post-invasion series rightward.
#'
#' `.hjust` points the text INWARD from that end (0 for a left-hand series, 1 for
#' a right-hand one), so an arbitrarily long label can never be clipped by the
#' panel edge. Draw with a small negative `vjust` to sit the text above its line.
#'
#' @param df Data frame containing the series, x and y columns
#' @param series_col Name of the grouping column, as a string
#' @param x_col,y_col Names of the x and y columns, as strings
#' @return Tibble with columns .series, .x, .y, .hjust
series_label_positions <- function(df, series_col, x_col = "running",
                                   y_col = "sentiment_clean") {
  df %>%
    rename(.series = all_of(series_col), .x = all_of(x_col), .y = all_of(y_col)) %>%
    group_by(.series) %>%
    group_modify(~ {
      fit  <- lm(.y ~ .x, data = .x)
      xend <- if (max(.x$.x, na.rm = TRUE) <= 0) min(.x$.x, na.rm = TRUE)
              else max(.x$.x, na.rm = TRUE)
      tibble(.x = xend,
             .y = unname(predict(fit, newdata = data.frame(.x = xend))),
             .hjust = if (xend <= 0) 0 else 1)
    }) %>%
    ungroup()
}

# -----------------------------------------------------------------------------
# Time Specification Helper Functions
# -----------------------------------------------------------------------------

#' Check if a date string includes publication time
#'
#' @param date_col Character vector of date strings
#' @return Logical vector: TRUE if the string has a time component (length > 10)
has_publication_time <- function(date_col) {
  str_length(date_col) > 10
}

#' Assign probabilistic publication times via KDE
#'
#' For articles missing a time component, samples a time-of-day from a KDE
#' fitted to observed times within the same source (or country as fallback).
#'
#' @param data Data frame
#' @param date_col_name Name of the raw date character column
#' @param source_col Name of the source grouping column
#' @param country_col Name of the country grouping column
#' @param min_obs Minimum observations for source-level KDE (default 5)
#' @return POSIXct vector with original datetimes preserved and missing times filled
assign_probabilistic_time <- function(data, date_col_name, source_col, country_col, min_obs = 5) {
  date_col <- data[[date_col_name]]
  has_time <- has_publication_time(date_col)

  # Parse all datetimes
  parsed <- clean_datetime_col(date_col)

  # Extract time-of-day in seconds from midnight for articles WITH times
  time_seconds <- as.numeric(difftime(parsed, floor_date(parsed, "day"), units = "secs"))

  # Build KDE by source
  source_vals <- data[[source_col]]
  country_vals <- data[[country_col]]

  # Pre-compute country-level KDEs as fallback
  country_kdes <- list()
  for (cntry in unique(country_vals)) {
    idx <- which(has_time & country_vals == cntry)
    if (length(idx) >= min_obs) {
      country_kdes[[cntry]] <- density(time_seconds[idx], from = 0, to = 86399, n = 1024)
    }
  }
  # Global fallback
  global_kde <- density(time_seconds[has_time], from = 0, to = 86399, n = 1024)

  # For each article without time, sample from appropriate KDE
  result <- parsed
  missing_idx <- which(!has_time)

  if (length(missing_idx) > 0) {
    sampled_seconds <- numeric(length(missing_idx))

    for (i in seq_along(missing_idx)) {
      row_idx <- missing_idx[i]
      src <- source_vals[row_idx]
      cntry <- country_vals[row_idx]

      # Try source-level KDE
      src_idx <- which(has_time & source_vals == src)
      if (length(src_idx) >= min_obs) {
        kde <- density(time_seconds[src_idx], from = 0, to = 86399, n = 1024)
      } else if (!is.null(country_kdes[[cntry]])) {
        kde <- country_kdes[[cntry]]
      } else {
        kde <- global_kde
      }

      # Sample from KDE
      s <- sample(kde$x, size = 1, replace = TRUE, prob = kde$y)
      s <- s + runif(1, -kde$bw / 2, kde$bw / 2)
      sampled_seconds[i] <- max(0, min(86399, s))
    }

    # Assign: date (at midnight) + sampled seconds
    result[missing_idx] <- floor_date(parsed[missing_idx], "day") + seconds(sampled_seconds)
  }

  return(result)
}

# -----------------------------------------------------------------------------
# Publication Output Helpers
# -----------------------------------------------------------------------------

create_bootstrap_vcov <- function(model, boot_result, coef_name) {
  original_vcov <- vcov(model)
  modified_vcov <- original_vcov
  coef_idx <- which(names(coef(model)) == coef_name)
  if (length(coef_idx) > 0 && !is.null(boot_result$se)) {
    modified_vcov[coef_idx, coef_idx] <- boot_result$se^2
  }
  return(modified_vcov)
}

get_boot_stars <- function(p_val) {
  if (is.null(p_val) || is.na(p_val)) return("")
  if (p_val < 0.001) return("***")
  if (p_val < 0.01) return("**")
  if (p_val < 0.05) return("*")
  if (p_val < 0.1) return("+")
  return("")
}

override_interaction_stars <- function(tbl, boot_results, col_names, row_idx = 3) {
  for (i in seq_along(boot_results)) {
    boot_p <- boot_results[[i]]$p_val
    stars <- get_boot_stars(boot_p)
    make_fn <- function(s) {
      force(s)
      function(x) {
        val <- gsub("[+*]+$", "", x)
        paste0(val, s)
      }
    }
    tbl <- tbl %>%
      text_transform(
        locations = cells_body(columns = col_names[i], rows = row_idx),
        fn = make_fn(stars)
      )
  }
  tbl
}

get_n_clusters <- function(model) {
  tryCatch({
    if ("fixest" %in% class(model)) {
      n_cl <- attr(model$cov.scaled, "G")
      if (!is.null(n_cl)) return(as.character(n_cl))
    }
    return("—")
  }, error = function(e) "—")
}

# Normalise the LaTeX caption block and set the cross-reference label.
#
# gt writes two different caption shapes. A table built through modelsummary
# carries a knitr caption, \caption{\label{tab:<chunk>}Title}, which is what we
# want. A table built with gt() %>% tab_header() carries gt's own header, which
# becomes an *unnumbered* \caption*{} block set in 20pt/14pt display fonts, and
# a malformed hybrid when a subtitle is present -- a stray \\ and a dangling
# {\fontsize{14}{17}...} group left outside the caption.
#
# Neither shape lets two tables built in the same chunk carry distinct labels,
# because knitr derives the label from the chunk name.
#
# This collapses every shape to one numbered caption at the house 12pt body
# size, carrying the label given. A subtitle, where there is one, is folded into
# the caption rather than dropped. The HTML output is untouched, so it keeps
# title and subtitle as gt renders them.
normalize_tex_caption <- function(filepath, label = NULL, sep = ". ") {
  if (!file.exists(filepath)) return(invisible(FALSE))
  lines <- readLines(filepath, warn = FALSE)

  cap_start <- grep("^\\s*\\\\caption\\*?\\{", lines)
  if (!length(cap_start)) return(invisible(FALSE))
  cap_start <- cap_start[1]

  # the body-font line closes the caption block in every gt LaTeX table
  body_font <- grep("^\\s*\\\\fontsize\\{12\\.0pt\\}", lines)
  body_font <- body_font[body_font > cap_start]
  cap_end <- if (length(body_font)) body_font[1] - 1L else cap_start

  txt <- paste(lines[cap_start:cap_end], collapse = "\n")

  # keep whatever label is already there unless an explicit one was supplied
  found <- regmatches(txt, regexpr("\\\\label\\{[^}]*\\}", txt))
  keep <- if (!is.null(label)) label
          else if (length(found)) sub("^\\\\label\\{(.*)\\}$", "\\1", found) else NULL

  txt <- gsub("\\\\label\\{[^}]*\\}", "", txt)
  txt <- sub("^\\s*\\\\caption\\*?\\{", "", txt)
  txt <- gsub("\\\\fontsize\\{[^}]*\\}\\{[^}]*\\}\\\\selectfont", "", txt)
  txt <- gsub("\\\\\\\\", "\n", txt)          # \\ separates title from subtitle

  pieces <- unlist(strsplit(txt, "\n", fixed = TRUE))
  pieces <- trimws(gsub("\\s+", " ", pieces))
  pieces <- sub("^\\{+", "", pieces)           # only boundary braces, so any
  pieces <- sub("\\}+$", "", pieces)           # braces inside the text survive
  pieces <- trimws(pieces)
  pieces <- pieces[nzchar(pieces)]
  if (!length(pieces)) return(invisible(FALSE))

  caption <- paste(pieces, collapse = sep)
  new_line <- if (is.null(keep)) sprintf("\\caption{%s}", caption)
              else sprintf("\\caption{\\label{%s}%s}", keep, caption)

  writeLines(c(lines[seq_len(cap_start - 1L)], new_line,
               lines[(cap_end + 1L):length(lines)]), filepath)
  invisible(TRUE)
}

# `label` is the full cross-reference target, e.g. "tab:s13". Omit it to leave
# whatever label knitr derived from the chunk name in place.
save_table <- function(tbl, name, subdir = NULL, label = NULL) {
  out_dir <- if (!is.null(subdir)) file.path(FIGURES_TABLES, subdir) else FIGURES_TABLES
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  tex_path <- file.path(out_dir, paste0(name, ".tex"))
  gtsave(tbl, tex_path)
  gtsave(tbl, file.path(out_dir, paste0(name, ".html")))
  normalize_tex_caption(tex_path, label = label)
  invisible(tbl)
}

SE_NOTE_BOOT <- "† Standard errors computed via wild cluster restricted (WCR) bootstrap (Cameron, Gelbach & Miller 2008) with Webb six-point weights (B=99999, null imposed), clustered by source domain."
SE_NOTE_RDROBUST <- "‡ Cluster-robust SEs from rdrobust."
SE_NOTE_CLUSTER <- "All standard errors are clustered at the source level."
SE_NOTE <- paste(SE_NOTE_BOOT, SE_NOTE_RDROBUST)

cat("Setup complete. Project root:", PROJECT_ROOT, "\n")
