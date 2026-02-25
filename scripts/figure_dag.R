# =============================================================================
# figure_dag.R
# Creates publication-ready DAGs for the Russia Sentiment Paper
# =============================================================================
#
# This script generates two separate DAG figures showing the causal structure:
#   A. Problem: Only controlling for Topic (backdoor path OPEN)
#   B. Solution: Controlling for Country, Ownership, and Topic (backdoor BLOCKED)
#
# Key features:
#   - Text-only nodes (no circles/shapes)
#   - Individual boxes around each control variable
#   - Backdoor path highlighted with dashed red arrows in the "problem" figure
#
# Color scheme:
#   - Blue text: Causal variables (Country, Media Ownership, Invasion)
#   - Orange arrows: Arrows into the collider (Topic)
#   - Green text: Outcome (Predicted Sentiment)
#   - Red dashed arrows: Open backdoor path (in problem figure)
#   - Black text: Mediating variables
#
# Output:
#   - figures/dag/figure_dag_problem.pdf/png (backdoor path open)
#   - figures/dag/figure_dag_solution.pdf/png (backdoor path blocked)
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
output_dir <- if (!is.null(project_dir)) file.path(project_dir, "figures", "dag") else NULL

# Fallback if not running in RStudio
if (is.null(output_dir) || output_dir == "") {
  output_dir <- "D:/Dropbox/My PC (LAPTOP-IKUHQKMA)/Documents/GitHub/russia_sentiment_paper/figures/dag"
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
  name = c("country", "ownership", "priorities", "tone", "topic",
           "invasion", "draft", "article", "sentiment"),
  x = c(1.0, 3.0, 1.0, 3.5, 2.2, 0, 4.0, 5.5, 7.0),
  y = c(4.0, 4.0, 2.5, 2.5, 1.5, 1.0, 1.0, 1.0, 1.0),
  label = c("Country", "Media\nOwnership", "Editorial\nPriorities", "Tone/Style",
            "Topic", "Invasion", "Journalist\nDraft", "Full Article\nText", "Predicted\nSentiment"),
  # Label alignment
  hjust = c(0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5),
  vjust = c(0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5),
  # Node types
  is_collider = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  is_causal = c(TRUE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE),
  is_outcome = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE),
  is_control = c(TRUE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Assign text colors based on node type
nodes_df$text_color <- ifelse(nodes_df$is_causal, colors$causal,
                        ifelse(nodes_df$is_collider, colors$collider,
                        ifelse(nodes_df$is_outcome, colors$outcome,
                               "black")))

# -----------------------------------------------------------------------------
# Define Edges (Arrows)
# -----------------------------------------------------------------------------

edges_df <- data.frame(
  from = c("country", "country", "country", "country",
           "ownership", "ownership", "priorities", "invasion", "invasion",
           "topic", "tone", "draft", "article"),
  to = c("ownership", "priorities", "tone", "topic",
         "priorities", "tone", "topic", "topic", "draft",
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
# Create the Solution DAG (Full model with all controls)
# -----------------------------------------------------------------------------

dag_solution <- ggplot() +

  # Box around Country
  annotate(
    "rect",
    xmin = 1.0 - 0.55, xmax = 1.0 + 0.55,
    ymin = 4.0 - 0.25, ymax = 4.0 + 0.25,
    fill = "gray95", color = "gray60",
    linetype = "dashed", linewidth = 0.5
  ) +

  # Box around Media Ownership
  annotate(
    "rect",
    xmin = 3.0 - 0.65, xmax = 3.0 + 0.65,
    ymin = 4.0 - 0.4, ymax = 4.0 + 0.4,
    fill = "gray95", color = "gray60",
    linetype = "dashed", linewidth = 0.5
  ) +

  # Box around Topic
  annotate(
    "rect",
    xmin = 2.2 - 0.45, xmax = 2.2 + 0.45,
    ymin = 1.5 - 0.25, ymax = 1.5 + 0.25,
    fill = "gray95", color = "gray60",
    linetype = "dashed", linewidth = 0.5
  ) +

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

  # Add text labels (no circles - text only)
  geom_text(
    data = nodes_df,
    aes(x = x, y = y, label = label, color = text_color),
    size = 2.8,
    family = "sans",
    lineheight = 0.85,
    fontface = "bold"
  ) +
  scale_color_identity() +

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
  coord_fixed(ratio = 0.7, xlim = c(-1, 8), ylim = c(-0.2, 5))

# -----------------------------------------------------------------------------
# Create the Problem DAG (Only controlling for Topic - shows open backdoor)
# -----------------------------------------------------------------------------

# For the problem DAG, we show only Topic boxed, and highlight the backdoor path in red
# The backdoor path is: Country -> Ownership -> Priorities -> Topic <- Invasion

# Mark which edges are part of the backdoor path
# The backdoor path goes: Topic <- Priorities <- Ownership <- Country -> Tone -> Article -> Sentiment
# (and also Ownership -> Tone)
edges_df$is_backdoor <- (edges_df$from == "priorities" & edges_df$to == "topic") |
                        (edges_df$from == "ownership" & edges_df$to == "priorities") |
                        (edges_df$from == "country" & edges_df$to == "ownership") |
                        (edges_df$from == "country" & edges_df$to == "tone") |
                        (edges_df$from == "ownership" & edges_df$to == "tone") |
                        (edges_df$from == "tone" & edges_df$to == "article") |
                        (edges_df$from == "article" & edges_df$to == "sentiment")

dag_problem <- ggplot() +

  # Box around Topic only (the only control in "problem" scenario)
  annotate(
    "rect",
    xmin = 2.2 - 0.45, xmax = 2.2 + 0.45,
    ymin = 1.5 - 0.25, ymax = 1.5 + 0.25,
    fill = "gray95", color = "gray60",
    linetype = "dashed", linewidth = 0.5
  ) +

  # Draw regular edges (gray) - excluding backdoor path
  geom_segment(
    data = edges_df[!edges_df$is_backdoor, ],
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.08, "inches"), type = "closed"),
    linewidth = 0.4,
    color = colors$arrow_regular,
    lineend = "round"
  ) +

  # Draw backdoor path edges in RED DASHED
  geom_segment(
    data = edges_df[edges_df$is_backdoor, ],
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.08, "inches"), type = "closed"),
    linewidth = 0.8,
    color = "#E41A1C",
    linetype = "dashed",
    lineend = "round"
  ) +

  # Add text labels
  geom_text(
    data = nodes_df,
    aes(x = x, y = y, label = label, color = text_color),
    size = 2.8,
    family = "sans",
    lineheight = 0.85,
    fontface = "bold"
  ) +
  scale_color_identity() +

  # Title indicating the problem
  ggtitle("A. Controlling for Topic Only\n(Backdoor path OPEN)") +

  # Clean theme
  theme_void() +
  theme(
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 9,
      color = "#E41A1C",
      margin = margin(b = 10)
    ),
    plot.margin = margin(10, 10, 10, 10, "pt"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  ) +

  # Fixed coordinates

  coord_fixed(ratio = 0.7, xlim = c(-1, 8), ylim = c(-0.2, 5))

# Update the solution DAG title
dag_solution <- dag_solution +
  ggtitle("B. Controlling for Country, Ownership, and Topic\n(Backdoor path BLOCKED)")

# Update solution title styling
dag_solution <- dag_solution +
  theme(
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 9,
      color = "#1B7837",
      margin = margin(b = 10)
    )
  )

# -----------------------------------------------------------------------------
# Print the Plots
# -----------------------------------------------------------------------------

print(dag_problem)
print(dag_solution)

# -----------------------------------------------------------------------------
# Export Figures (Two Separate Files)
# -----------------------------------------------------------------------------

# Export Problem DAG (backdoor path open)
ggsave(
  filename = file.path(output_dir, "figure_dag_problem.pdf"),
  plot = dag_problem,
  width = 7,
  height = 5,
  units = "in",
  device = "pdf"
)
cat("Saved:", file.path(output_dir, "figure_dag_problem.pdf"), "\n")

ggsave(
  filename = file.path(output_dir, "figure_dag_problem.png"),
  plot = dag_problem,
  width = 7,
  height = 5,
  units = "in",
  dpi = 300,
  bg = "white"
)
cat("Saved:", file.path(output_dir, "figure_dag_problem.png"), "\n")

# Export Solution DAG (backdoor path blocked)
ggsave(
  filename = file.path(output_dir, "figure_dag_solution.pdf"),
  plot = dag_solution,
  width = 7,
  height = 5,
  units = "in",
  device = "pdf"
)
cat("Saved:", file.path(output_dir, "figure_dag_solution.pdf"), "\n")

ggsave(
  filename = file.path(output_dir, "figure_dag_solution.png"),
  plot = dag_solution,
  width = 7,
  height = 5,
  units = "in",
  dpi = 300,
  bg = "white"
)
cat("Saved:", file.path(output_dir, "figure_dag_solution.png"), "\n")

# -----------------------------------------------------------------------------
# Session Info
# -----------------------------------------------------------------------------

cat("\n--- Session Info ---\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("R version:", R.version.string, "\n")
