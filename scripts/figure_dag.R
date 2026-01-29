# =============================================================================
# figure_dag.R
# Creates a publication-ready DAG for the Russia Sentiment Paper
# =============================================================================
#
# This script generates a Directed Acyclic Graph (DAG) showing the causal
# structure of the analysis. Key feature: Topic is highlighted as a COLLIDER
# (square shape, orange) because it receives arrows from both Invasion
# (treatment) and Editor Sets Priorities (influenced by Ownership).
#
# Color scheme:
#   - Blue: Key causal variables (Media Ownership, Invasion)
#   - Orange: Collider (Topic) and arrows into it
#   - Green: Outcome (Sentiment)
#   - White/Black: Mediating variables
#
# Output:
#   - figures/figure_dag.pdf (vector format for publication)
#   - figures/figure_dag.png (300 DPI raster)
#
# =============================================================================

# -----------------------------------------------------------------------------
# Load Required Packages
# -----------------------------------------------------------------------------

if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, grid)

# -----------------------------------------------------------------------------
# Set Output Directory
# -----------------------------------------------------------------------------

# Use explicit path relative to script location
script_dir <- tryCatch(
  dirname(rstudioapi::getSourceEditorContext()$path),
  error = function(e) NULL
)
project_dir <- if (!is.null(script_dir) && script_dir != "") dirname(script_dir) else NULL
output_dir <- if (!is.null(project_dir)) file.path(project_dir, "figures") else NULL

# Fallback if not running in RStudio
if (is.null(output_dir) || output_dir == "") {
  output_dir <- "D:/Dropbox/My PC (LAPTOP-IKUHQKMA)/Documents/GitHub/russia_sentiment_paper/figures"
}

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
cat("Output directory:", output_dir, "\n")

# -----------------------------------------------------------------------------
# Define Color Scheme
# -----------------------------------------------------------------------------

colors <- list(
  causal = "#2166AC",      # Blue - Media Ownership, Invasion
  collider = "#D95F02",    # Orange - Topic
  outcome = "#1B7837",     # Green - Sentiment
  mediator_fill = "white", # White fill for mediators
  mediator_border = "black",
  arrow_regular = "gray50",
  arrow_collider = "#D95F02"  # Orange arrows into collider
)

# -----------------------------------------------------------------------------
# Define Node Positions and Labels
# -----------------------------------------------------------------------------

nodes_df <- data.frame(
  name = c("ownership", "priorities", "tone", "topic",
           "invasion", "draft", "article", "sentiment"),
  x = c(0, 1.8, 3.6, 2.2, 2.2, 4, 5.5, 7),
  y = c(2.5, 3.5, 3.5, 2, 0.5, 2, 2.5, 2.5),
  label = c("Media\nOwnership", "Editor Sets\nPriorities", "Editor\nTone/Style",
            "Topic", "Invasion", "Journalist\nDraft", "Full Article\nText", "Sentiment"),
  # Label offsets (closer to nodes now)
  label_x_offset = c(0, 0, 0, 0.42, 0, 0, 0, 0),
  label_y_offset = c(-0.38, 0.38, 0.38, 0, -0.38, -0.38, -0.38, -0.38),
  # Label alignment
  hjust = c(0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5),
  vjust = c(1, 0, 0, 1, 1, 1, 1, 1),
  # Node types
  is_collider = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  is_causal = c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE),
  is_outcome = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE),
  stringsAsFactors = FALSE
)

# Assign fill colors based on node type
nodes_df$fill_color <- ifelse(nodes_df$is_causal, colors$causal,
                        ifelse(nodes_df$is_collider, colors$collider,
                        ifelse(nodes_df$is_outcome, colors$outcome,
                               colors$mediator_fill)))

# Assign border colors
nodes_df$border_color <- ifelse(nodes_df$fill_color == "white", "black", nodes_df$fill_color)

# Assign text colors (white text on dark backgrounds)
nodes_df$text_color <- ifelse(nodes_df$fill_color %in% c(colors$causal, colors$outcome),
                               "black", "black")

# Assign shapes (22 = square for collider, 21 = circle for others)
nodes_df$shape <- ifelse(nodes_df$is_collider, 22, 21)

# -----------------------------------------------------------------------------
# Define Edges (Arrows)
# -----------------------------------------------------------------------------

edges_df <- data.frame(
  from = c("ownership", "ownership", "priorities", "priorities", "invasion",
           "topic", "tone", "draft", "article"),
  to = c("priorities", "tone", "tone", "topic", "topic",
         "draft", "article", "article", "sentiment"),
  stringsAsFactors = FALSE
)

# Add coordinates to edges
edges_df$x <- nodes_df$x[match(edges_df$from, nodes_df$name)]
edges_df$y <- nodes_df$y[match(edges_df$from, nodes_df$name)]
edges_df$xend <- nodes_df$x[match(edges_df$to, nodes_df$name)]
edges_df$yend <- nodes_df$y[match(edges_df$to, nodes_df$name)]
edges_df$is_collider_edge <- edges_df$to == "topic"

# Assign arrow colors
edges_df$arrow_color <- ifelse(edges_df$is_collider_edge, colors$arrow_collider, colors$arrow_regular)

# Shorten arrows so they don't overlap with nodes
shorten_arrow <- function(x, y, xend, yend, shorten_start = 0.30, shorten_end = 0.30) {
  dx <- xend - x
  dy <- yend - y
  len <- sqrt(dx^2 + dy^2)
  if (len == 0) return(c(x, y, xend, yend))

  ux <- dx / len
  uy <- dy / len

  new_x <- x + ux * shorten_start
  new_y <- y + uy * shorten_start
  new_xend <- xend - ux * shorten_end
  new_yend <- yend - uy * shorten_end

  return(c(new_x, new_y, new_xend, new_yend))
}

# Apply shortening to all edges
for (i in 1:nrow(edges_df)) {
  coords <- shorten_arrow(
    edges_df$x[i], edges_df$y[i],
    edges_df$xend[i], edges_df$yend[i],
    shorten_start = 0.38, shorten_end = 0.38
  )
  edges_df$x[i] <- coords[1]
  edges_df$y[i] <- coords[2]
  edges_df$xend[i] <- coords[3]
  edges_df$yend[i] <- coords[4]
}

# -----------------------------------------------------------------------------
# Create the Plot
# -----------------------------------------------------------------------------

dag_plot <- ggplot() +

  # Draw regular edges (gray)
  geom_segment(
    data = edges_df[!edges_df$is_collider_edge, ],
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.08, "inches"), type = "closed"),
    linewidth = 0.4,
    color = colors$arrow_regular,
    lineend = "round"
  ) +

  # Draw collider edges (orange)
  geom_segment(
    data = edges_df[edges_df$is_collider_edge, ],
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.08, "inches"), type = "closed"),
    linewidth = 0.6,
    color = colors$arrow_collider,
    lineend = "round"
  ) +

  # Draw mediator nodes (white circles)
  geom_point(
    data = nodes_df[!nodes_df$is_collider & !nodes_df$is_causal & !nodes_df$is_outcome, ],
    aes(x = x, y = y),
    shape = 21,
    size = 12,
    fill = colors$mediator_fill,
    color = colors$mediator_border,
    stroke = 0.8
  ) +

  # Draw causal nodes (blue circles) - Ownership and Invasion
  geom_point(
    data = nodes_df[nodes_df$is_causal, ],
    aes(x = x, y = y),
    shape = 21,
    size = 12,
    fill = colors$causal,
    color = colors$causal,
    stroke = 0.8
  ) +

  # Draw outcome node (green circle) - Sentiment
  geom_point(
    data = nodes_df[nodes_df$is_outcome, ],
    aes(x = x, y = y),
    shape = 21,
    size = 12,
    fill = colors$outcome,
    color = colors$outcome,
    stroke = 0.8
  ) +

  # Draw collider node (orange SQUARE) - Topic
  geom_point(
    data = nodes_df[nodes_df$is_collider, ],
    aes(x = x, y = y),
    shape = 22,  # Square
    size = 12,
    fill = colors$collider,
    color = colors$collider,
    stroke = 0.8
  ) +

  # Add text labels
  geom_text(
    data = nodes_df,
    aes(x = x + label_x_offset,
        y = y + label_y_offset,
        label = label,
        hjust = hjust,
        vjust = vjust),
    size = 2.8,
    family = "sans",
    lineheight = 0.85,
    color = "black"
  ) +

  # Add title
  ggtitle("Causal Graph for the Impact of Invasion on Sentiment") +

  # Clean theme

  theme_void() +
  theme(
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 10,
      margin = margin(b = 10)
    ),
    plot.margin = margin(10, 10, 10, 10, "pt"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  ) +

  # Fixed coordinates
  coord_fixed(ratio = 0.7, xlim = c(-1, 8), ylim = c(-0.2, 4.3))

# Print the plot
print(dag_plot)

# -----------------------------------------------------------------------------
# Export Figures
# -----------------------------------------------------------------------------

# Export as PDF (vector format for publication)
ggsave(
  filename = file.path(output_dir, "figure_dag.pdf"),
  plot = dag_plot,
  width = 7,
  height = 5.6,
  units = "in",
  device = "pdf"
)
cat("Saved:", file.path(output_dir, "figure_dag.pdf"), "\n")

# Export as PNG (300 DPI for submission)
ggsave(
  filename = file.path(output_dir, "figure_dag.png"),
  plot = dag_plot,
  width = 3.5,
  height = 2.8,
  units = "in",
  dpi = 300,
  bg = "white"
)
cat("Saved:", file.path(output_dir, "figure_dag.png"), "\n")

# Also save a larger version for presentations
ggsave(
  filename = file.path(output_dir, "figure_dag_large.png"),
  plot = dag_plot,
  width = 7,
  height = 5.6,
  units = "in",
  dpi = 300,
  bg = "white"
)
cat("Saved:", file.path(output_dir, "figure_dag_large.png"), "\n")

# -----------------------------------------------------------------------------
# Session Info
# -----------------------------------------------------------------------------

cat("\n--- Session Info ---\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("R version:", R.version.string, "\n")
