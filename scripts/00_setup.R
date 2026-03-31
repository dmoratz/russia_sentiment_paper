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

# Set seed for reproducibility
set.seed(3184)

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

# Wild cluster bootstrap helper (used in 05/06 family)
run_wild_bootstrap <- function(model, param, clustid = "source_domain", B = 4999) {
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

save_table <- function(tbl, name, subdir = NULL) {
  out_dir <- if (!is.null(subdir)) file.path(FIGURES_TABLES, subdir) else FIGURES_TABLES
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  gtsave(tbl, file.path(out_dir, paste0(name, ".tex")))
  gtsave(tbl, file.path(out_dir, paste0(name, ".html")))
  invisible(tbl)
}

SE_NOTE_BOOT <- "† Standard errors computed via wild cluster restricted (WCR) bootstrap (Cameron, Gelbach & Miller 2008) with Webb six-point weights (B=4999, null imposed), clustered by source domain."
SE_NOTE_RDROBUST <- "‡ Cluster-robust SEs from rdrobust."
SE_NOTE_CLUSTER <- "All standard errors are clustered at the source level."
SE_NOTE <- paste(SE_NOTE_BOOT, SE_NOTE_RDROBUST)

cat("Setup complete. Project root:", PROJECT_ROOT, "\n")
