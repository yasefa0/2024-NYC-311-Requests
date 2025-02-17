# status_distribution.R
# Purpose: Show distribution of current status

library(arrow)
library(dplyr)
library(ggplot2)

# 1. Read Parquet
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Count how many requests are in each status
status_counts <- df %>%
  group_by(status) %>%
  summarise(requests = n()) %>%
  arrange(desc(requests))

# 3. Pie chart or bar chart (example uses bar chart)
ggplot(status_counts, aes(x = "", y = requests, fill = status)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  labs(title = "Distribution of 311 Request Status") +
  theme_void()  # Removes the x,y axis

