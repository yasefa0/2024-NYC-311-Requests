# borough_distribution.R
# Purpose: Bar chart of requests by NYC borough

library(arrow)
library(dplyr)
library(ggplot2)

# 1. Read Parquet
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Count by borough
borough_counts <- df %>%
  group_by(borough) %>%
  summarise(requests = n()) %>%
  arrange(desc(requests))

# 3. Basic bar chart
ggplot(borough_counts, aes(x = reorder(borough, -requests), y = requests)) +
  geom_bar(stat = "identity", fill = "firebrick") +
  labs(
    title = "311 Requests by Borough",
    x = "Borough",
    y = "Number of Requests"
  ) +
  theme_minimal()
