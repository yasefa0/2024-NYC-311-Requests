# agency_barchart.R
# Purpose: Bar chart showing the count of requests per agency

library(arrow)
library(dplyr)
library(ggplot2)

# 1. Read the Parquet data
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Count by agency
agency_counts <- df %>%
  group_by(agency) %>%
  summarise(requests = n()) %>%
  arrange(desc(requests))

# 3. Basic bar plot (top 10 agencies for readability)
agency_counts_top10 <- agency_counts %>% slice_max(order_by = requests, n = 10)

ggplot(agency_counts_top10, aes(x = reorder(agency, -requests), y = requests)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  labs(
    title = "Top 10 Agencies by 311 Requests",
    x = "Agency",
    y = "Number of Requests"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
