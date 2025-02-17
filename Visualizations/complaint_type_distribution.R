# complaint_type_distribution.R
# Purpose: Show distribution of complaint types

library(arrow)
library(dplyr)
library(ggplot2)

# 1. Read Parquet
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Count by complaint_type
complaint_counts <- df %>%
  group_by(complaint_type) %>%
  summarise(requests = n()) %>%
  arrange(desc(requests))

# 3. Plot bar chart of top 10 complaint types
complaint_counts_top10 <- complaint_counts %>% slice_max(order_by = requests, n = 10)

ggplot(complaint_counts_top10, aes(x = reorder(complaint_type, -requests), y = requests)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  labs(
    title = "Top 10 Complaint Types",
    x = "Complaint Type",
    y = "Number of Requests"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
