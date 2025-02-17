# submission_methods_adjusted.R
#
# Purpose: Create a bar chart showing the number of complaints received via different submission methods,
#          excluding the "OTHER" category, formatting x-axis labels with commas, and adding an extra tick mark.

# Load Required Libraries
library(arrow)      # For reading Parquet files
library(dplyr)      # Data manipulation
library(ggplot2)    # Visualization
library(scales)     # For formatting numbers with commas

# 1. Load the Dataset
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Filter Out "OTHER" Submission Method
submission_counts <- df %>%
  filter(open_data_channel_type != "OTHER") %>%
  group_by(open_data_channel_type) %>%
  summarise(request_count = n(), .groups = "drop") %>%
  arrange(desc(request_count))

# Find a good x-axis scale
max_value <- max(submission_counts$request_count)
breaks_seq <- seq(0, max_value, length.out = 6)  # Add an extra tick mark

# 3. Create a Bar Chart
p <- ggplot(submission_counts, aes(x = reorder(open_data_channel_type, request_count), y = request_count, fill = open_data_channel_type)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Number of Complaints by Submission Method",
    x = "Submission Method",
    y = "Number of Complaints"
  ) +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_y_continuous(labels = comma, breaks = breaks_seq)  # Add extra tick marks

# 4. Print the Plot
print(p)

# 5. (Optional) Save the Plot as an Image
ggsave("submission_methods_adjusted.png", p, width = 10, height = 6)
