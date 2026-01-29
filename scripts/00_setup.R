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
  zoo
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
    fig.path = "../figures/",
    cache = FALSE
  )
}

cat("Setup complete. Project root:", PROJECT_ROOT, "\n")
