# bridge_highway_visuals.R
#
# Purpose: 
# 1) Bar Chart: Requests by bridge or highway name
# 2) Simple Map: Plot complaint hotspots for those requests (assuming lat/long).

library(arrow)    # for reading Parquet
library(dplyr)    # data manipulation
library(ggplot2)  # plotting
library(maps)     # provides map_data for basic outlines

# ------------------------------------------------------------------------------
# 1. Read the Parquet File
# ------------------------------------------------------------------------------
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# ------------------------------------------------------------------------------
# 2. Filter Rows with a Valid bridge_highway_name
# ------------------------------------------------------------------------------
df_bridge <- df %>%
  filter(!is.na(bridge_highway_name) & bridge_highway_name != "")

# If you also have many blank or "UNSPECIFIED" values, filter them out similarly:
#   filter(!is.na(bridge_highway_name) & bridge_highway_name != "" & bridge_highway_name != "Unspecified")

# ------------------------------------------------------------------------------
# 3. Bar Chart of Request Counts by bridge_highway_name
# ------------------------------------------------------------------------------
# Summarize counts
bridge_counts <- df_bridge %>%
  group_by(bridge_highway_name) %>%
  summarise(request_count = n()) %>%
  arrange(desc(request_count))

# (Optional) If you have many highway names, you might only plot the top 10 or 15:
top_bridges <- bridge_counts %>% 
  slice_head(n = 10)  # top 10

# Plot bar chart
p1 <- ggplot(top_bridges, aes(x = reorder(bridge_highway_name, -request_count), y = request_count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(
    title = "Top 10 Bridge/Highway Names by 311 Request Volume",
    x = "Bridge/Highway Name",
    y = "Number of Requests"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p1)

# ------------------------------------------------------------------------------
# 4. Map of Bridge/Highway Complaint Hotspots
# ------------------------------------------------------------------------------
# For a simple approach, we'll use the "maps" package to get a rough outline of NY.
# If you have an exact shapefile or GeoJSON for NYC, consider using the 'sf' package.

# We assume your data has columns 'latitude' and 'longitude'.
# (Adjust to your actual column names if needed)
# Filter out rows without valid lat/long to avoid plotting NA points.
df_bridge_map <- df_bridge %>%
  filter(!is.na(latitude) & !is.na(longitude))

# We'll fetch a rough outline of New York (or just "county" data for "new york").
# If your data is strictly NYC, you'll have a bigger area than needed, but it still shows context.
ny_map <- map_data("county", region = "new york")

p2 <- ggplot() +
  geom_polygon(
    data = ny_map, 
    aes(x = long, y = lat, group = group),
    fill = "gray90",
    color = "white"
  ) +
  geom_point(
    data = df_bridge_map,
    aes(x = longitude, y = latitude),
    color = "red",
    alpha = 0.5,
    size = 1
  ) +
  coord_quickmap() +
  labs(
    title = "Bridge/Highway Complaint Hotspots",
    subtitle = "Approximate locations (red points)"
  ) +
  theme_minimal()

print(p2)

# --------------------------------------------------------------------
# OPTIONAL: Save the plots to files
# --------------------------------------------------------------------
# ggsave("bridge_highway_bar_chart.png", p1, width = 10, height = 6)
# ggsave("bridge_highway_hotspots_map.png", p2, width = 10, height = 8)
