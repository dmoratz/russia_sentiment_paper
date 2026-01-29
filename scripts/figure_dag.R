# =============================================================================
# figure_dag.R
# Creates a publication-ready DAG for the Russia Sentiment Paper
# =============================================================================
#
# This script generates a Directed Acyclic Graph (DAG) showing the causal
# structure of the analysis. Key feature: Topic is highlighted as a COLLIDER
# because it receives arrows from both Invasion (treatment) and Editor Sets
# Priorities (influenced by Ownership).
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
pacman::p_load(
  ggdag,
  dagitty,
  ggplot2,
  ggraph,
  tidygraph
)

# -----------------------------------------------------------------------------
# Define the DAG Structure
# -----------------------------------------------------------------------------

# Create the DAG using dagify()
# Format: outcome ~ cause (arrow points from cause to outcome)

dag <- dagify(
  # Editorial process
  priorities ~ ownership,
  tone ~ ownership,
  tone ~ priorities,

  # Topic selection (COLLIDER - receives from priorities AND invasion)
  topic ~ priorities,
  topic ~ invasion,

  # Article production
  draft ~ topic,
  article ~ draft,
  article ~ tone,

  # Outcome
  sentiment ~ article,

  # Labels for display (clean, readable names)
  labels = c(
    ownership = "Media\nOwnership",
    priorities = "Editor Sets\nPriorities",
    tone = "Editor\nTone/Style",
    topic = "Topic",
    invasion = "Invasion",
    draft = "Journalist\nDraft",
    article = "Full Article\nText",
    sentiment = "Sentiment"
  ),

  # Identify treatment and outcome for ggdag
  exposure = "invasion",
  outcome = "sentiment"
)

# -----------------------------------------------------------------------------
# Set Node Coordinates (matching whiteboard layout)
# -----------------------------------------------------------------------------

# Define coordinates to match the sketch layout
# x: left to right (0 to 6)
# y: bottom to top (0 to 3)

coords <- list(
  x = c(
    ownership = 0,
    priorities = 1.5,
    tone = 3,
    topic = 2,
    invasion = 2,
    draft = 3.5,
    article = 5,
    sentiment = 6.5
  ),
  y = c(
    ownership = 2,
    priorities = 3,
    tone = 3,
    topic = 1.5,
    invasion = 0,
    draft = 1.5,
    article = 2,
    sentiment = 2
  )
)

# Apply coordinates to the DAG
dag_coords <- dag %>%
  tidy_dagitty() %>%
  dag_label() %>%
  mutate(
    x = coords$x[name],
    y = coords$y[name],
    xend = coords$x[to],
    yend = coords$y[to]
  )

# -----------------------------------------------------------------------------
# Identify Collider for Highlighting
# -----------------------------------------------------------------------------

# Mark Topic as the collider
dag_coords <- dag_coords %>%
  mutate(
    is_collider = (name == "topic"),
    node_fill = ifelse(is_collider, "gray80", "white"),
    # Identify edges pointing INTO the collider (for thicker arrows)
    is_collider_edge = (to == "topic" & !is.na(to))
  )

# -----------------------------------------------------------------------------
# Create the Plot
# -----------------------------------------------------------------------------

# Define consistent styling
node_size <- 18
text_size <- 2.5
arrow_size <- 0.2
edge_width_normal <- 0.4
edge_width_collider <- 0.8

dag_plot <- ggplot(dag_coords, aes(x = x, y = y, xend = xend, yend = yend)) +

 # Draw edges (arrows) - thicker for collider edges
  geom_dag_edges_arc(
    data = . %>% filter(!is_collider_edge | is.na(is_collider_edge)),
    edge_width = edge_width_normal,
    edge_colour = "gray30",
    curvature = 0,
    arrow_directed = grid::arrow(length = grid::unit(arrow_size, "inches"), type = "closed")
  ) +

  # Thicker arrows pointing to collider
 geom_dag_edges_arc(
    data = . %>% filter(is_collider_edge),
    edge_width = edge_width_collider,
    edge_colour = "black",
    curvature = 0,
    arrow_directed = grid::arrow(length = grid::unit(arrow_size * 1.2, "inches"), type = "closed")
  ) +

  # Draw nodes - collider gets gray fill
  geom_dag_point(
    aes(fill = node_fill),
    size = node_size,
    shape = 21,
    colour = "black",
    stroke = 1
  ) +

  # Add labels
  geom_dag_label_repel(
    aes(label = label),
    size = text_size,
    fontface = "plain",
    family = "sans",
    box.padding = 0.5,
    point.padding = 0.3,
    segment.color = "transparent",
    color = "black",
    fill = "white",
    label.size = 0
  ) +

  # Use the fill colors we defined
  scale_fill_identity() +

  # Clean theme for publication
  theme_dag_blank() +
  theme(
    plot.margin = margin(5, 5, 5, 5, "pt"),
    legend.position = "none"
  ) +

  # Set aspect ratio
  coord_fixed(ratio = 1, clip = "off")

# -----------------------------------------------------------------------------
# Alternative: Manual ggplot approach for more control
# -----------------------------------------------------------------------------

# Create a cleaner version with manual node and edge drawing

# Node data
nodes_df <- data.frame(
  name = names(coords$x),
  x = unlist(coords$x),
  y = unlist(coords$y),
  label = c(
    "Media\nOwnership",
    "Editor Sets\nPriorities",
    "Editor\nTone/Style",
    "Topic",
    "Invasion",
    "Journalist\nDraft",
    "Full Article\nText",
    "Sentiment"
  ),
  is_collider = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  is_treatment = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE),
  is_outcome = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE)
)

# Edge data (from -> to)
edges_df <- data.frame(
  from = c("ownership", "ownership", "priorities", "priorities", "invasion",
           "topic", "tone", "draft", "article"),
  to = c("priorities", "tone", "tone", "topic", "topic",
         "draft", "article", "article", "sentiment")
)

# Add coordinates to edges
edges_df <- edges_df %>%
  mutate(
    x = coords$x[from],
    y = coords$y[from],
    xend = coords$x[to],
    yend = coords$y[to],
    is_collider_edge = (to == "topic")
  )

# Create the final plot
dag_plot_final <- ggplot() +

  # Draw regular edges
  geom_segment(
    data = edges_df %>% filter(!is_collider_edge),
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.15, "inches"), type = "closed"),
    linewidth = 0.5,
    color = "gray40"
  ) +

  # Draw collider edges (thicker, darker)
  geom_segment(
    data = edges_df %>% filter(is_collider_edge),
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.18, "inches"), type = "closed"),
    linewidth = 0.9,
    color = "black"
  ) +

  # Draw nodes - regular (white fill)
  geom_point(
    data = nodes_df %>% filter(!is_collider),
    aes(x = x, y = y),
    shape = 21,
    size = 14,
    fill = "white",
    color = "black",
    stroke = 0.8
  ) +

  # Draw collider node (gray fill)
  geom_point(
    data = nodes_df %>% filter(is_collider),
    aes(x = x, y = y),
    shape = 21,
    size = 14,
    fill = "gray75",
    color = "black",
    stroke = 1.2
  ) +

  # Add text labels
  geom_text(
    data = nodes_df,
    aes(x = x, y = y, label = label),
    size = 2.8,
    family = "sans",
    lineheight = 0.85
  ) +

  # Minimal theme
  theme_void() +
  theme(
    plot.margin = margin(10, 10, 10, 10, "pt")
  ) +

  # Fixed aspect ratio
  coord_fixed(ratio = 0.8, xlim = c(-0.8, 7.3), ylim = c(-0.5, 3.8))

# Print the plot
print(dag_plot_final)

# -----------------------------------------------------------------------------
# Export Figures
# -----------------------------------------------------------------------------

# Set output directory
output_dir <- file.path(dirname(getwd()), "figures")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Export as PDF (vector format for publication)
ggsave(
  filename = file.path(output_dir, "figure_dag.pdf"),
  plot = dag_plot_final,
  width = 3.5,
  height = 2.5,
  units = "in",
  device = cairo_pdf
)

cat("Saved: figure_dag.pdf\n")

# Export as PNG (300 DPI for submission)
ggsave(
  filename = file.path(output_dir, "figure_dag.png"),
  plot = dag_plot_final,
  width = 3.5,
  height = 2.5,
  units = "in",
  dpi = 300,
  bg = "white"
)

cat("Saved: figure_dag.png\n")

# Also save a larger version for presentations
ggsave(
  filename = file.path(output_dir, "figure_dag_large.png"),
  plot = dag_plot_final,
  width = 7,
  height = 5,
  units = "in",
  dpi = 300,
  bg = "white"
)

cat("Saved: figure_dag_large.png\n")

# -----------------------------------------------------------------------------
# Session Info
# -----------------------------------------------------------------------------

cat("\n--- Session Info ---\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("R version:", R.version.string, "\n")
