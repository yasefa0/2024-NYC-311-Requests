# most_common_complaint_by_hour.R
# Purpose: Identify and plot the most common 311 complaint type for each hour block (0-23).

# -----------------------------
# 1. Load Libraries
# -----------------------------
library(arrow)      # for reading Parquet files
library(dplyr)      # for data manipulation
library(ggplot2)    # for plotting
library(lubridate)  # for easy date/time parsing and extraction

# -----------------------------
# 2. Read Parquet File
# -----------------------------
# Adjust path to your actual Parquet file
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# -----------------------------
# 3. Extract Hour from created_date
# -----------------------------
# Convert created_date to a proper datetime. Modify format if your data is different.
# If your created_date is already recognized as datetime, you can skip the parsing step.
df <- df %>%
  mutate(
    # Convert string to POSIXct; if it's "YYYY-MM-DD HH:MM:SS", this should work directly:
    created_datetime = ymd_hms(created_date, tz = "America/New_York"), 
    # Extract the hour (0-23)
    hour_of_day = hour(created_datetime)
  )

# -----------------------------
# 4. Find the Most Common Complaint for Each Hour
# -----------------------------
# We'll count how many requests there are for each (hour_of_day, complaint_type) pair
# and pick the top 1 for each hour.
most_common_by_hour <- df %>%
  group_by(hour_of_day, complaint_type) %>%
  summarise(request_count = n(), .groups = "drop") %>%
  # Within each hour, pick the complaint_type with the highest count
  slice_max(order_by = request_count, n = 1, with_ties = FALSE)

# -----------------------------
# 5. Plot: Bar Chart of Top Complaint by Hour
# -----------------------------
# Each hour (0-23) on x-axis, number of requests on y-axis, fill by complaint_type
ggplot(most_common_by_hour, aes(x = factor(hour_of_day), y = request_count, fill = complaint_type)) +
  geom_col() +
  labs(
    title = "Most Common 311 Complaint by Hour of Day",
    x = "Hour of Day (0–23)",
    y = "Number of Requests",
    fill = "Complaint Type"
  ) +
  theme_minimal()

# If you’d like to save the plot to a file:
# ggsave("most_common_complaint_by_hour.png", width = 10, height = 6)
