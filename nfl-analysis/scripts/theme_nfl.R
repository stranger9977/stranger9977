# Shared chart theme + validated palette for all charts in this project.
# Categorical slots must be used in this fixed order, never cycled or skipped.
library(ggplot2)

pal_cat <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100",
             "#e87ba4", "#008300", "#4a3aa7", "#e34948")
pal_seq <- c("#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5",
             "#256abf", "#184f95", "#0d366b")           # blue, light -> dark
pal_div <- list(low = "#2a78d6", mid = "#f0efec", high = "#e34948")  # blue-gray-red

ink_primary   <- "#0b0b0b"
ink_secondary <- "#52514e"
ink_muted     <- "#898781"
col_grid      <- "#e1e0d9"
col_baseline  <- "#c3c2b7"
col_surface   <- "#fcfcfb"

theme_nfl <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      text                = element_text(color = ink_primary),
      plot.background     = element_rect(fill = col_surface, color = NA),
      panel.background    = element_rect(fill = col_surface, color = NA),
      panel.grid.major    = element_line(color = col_grid, linewidth = 0.3),
      panel.grid.minor    = element_blank(),
      axis.text           = element_text(color = ink_muted, size = base_size * 0.75),
      axis.title          = element_text(color = ink_secondary, size = base_size * 0.85),
      plot.title          = element_text(face = "bold", size = base_size * 1.25,
                                         color = ink_primary),
      plot.subtitle       = element_text(color = ink_secondary, size = base_size * 0.9,
                                         margin = margin(b = 12)),
      plot.caption        = element_text(color = ink_muted, size = base_size * 0.65,
                                         hjust = 0),
      legend.text         = element_text(color = ink_secondary),
      legend.title        = element_text(color = ink_secondary),
      plot.title.position = "plot",
      plot.margin         = margin(16, 20, 12, 16)
    )
}

# Portable project root: works on the cloud Linux box and on the local Mac.
nfl_root <- local({
  cands <- c("/Users/nick/stranger9977/nfl-analysis",
             "/home/user/stranger9977/nfl-analysis")
  hit <- cands[dir.exists(cands)]
  if (length(hit)) hit[1] else getwd()
})

save_chart <- function(p, name, width = 10, height = 6.5) {
  path <- file.path(nfl_root, "charts", paste0(name, ".png"))
  ggsave(path, p, width = width, height = height, dpi = 150, bg = col_surface)
  cat("SAVED:", path, "\n")
}
