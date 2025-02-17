# top5_reasons_by_location_type.R
#
# Purpose: For each location_type, find the top 5 most common complaint types (a.k.a. “reasons”).

# 1. Load Libraries
library(arrow)   # for reading Parquet files
library(dplyr)   # for data manipulation

# 2. Read the Parquet File
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 3. Replace NA or blank location_type with something descriptive
df$location_type[is.na(df$location_type) | df$location_type == ""] <- "UNKNOWN"

# 4. Group by location_type + complaint_type, count the occurrences
complaints_by_location <- df %>%
  group_by(location_type, complaint_type) %>%
  summarise(request_count = n(), .groups = "drop")

# 5. For each location_type, pick the top 5 complaint types
#    We'll do this by grouping again and taking the head of each group
top5_by_location <- complaints_by_location %>%
  group_by(location_type) %>%
  slice_max(order_by = request_count, n = 5)

# 6. Print the results
#    You’ll see each location_type, along with its top 5 complaint types and their counts
print(top5_by_location, n = 50)  # prints first 50 rows for a quick look, or use Inf for all

# Alternatively, if you want to see them fully:
# print(top5_by_location, n = Inf)
