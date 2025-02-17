# time_series_plot.R
# Purpose: Create a daily time series chart of 311 requests

# Load required libraries
library(arrow)    # For reading Parquet files
library(dplyr)    # For data manipulation
library(ggplot2)  # For plotting

# 1. Read the Parquet data (adjust the path to your file)
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Convert 'created_date' from character to Date (assuming format "YYYY-MM-DD HH:MM:SS")
df <- df %>%
  mutate(created_date = as.Date(created_date, format="%Y-%m-%d %H:%M:%S"))

# 3. Aggregate counts by day
daily_counts <- df %>%
  group_by(created_date) %>%
  summarise(requests = n())

# 4. Plot a time series line chart
ggplot(daily_counts, aes(x = created_date, y = requests)) +
  geom_line(color = "steelblue") +
  labs(
    title = "Daily 311 Requests Over Time",
    x = "Date",
    y = "Number of Requests"
  ) +
  theme_minimal()
