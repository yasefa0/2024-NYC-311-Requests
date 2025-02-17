# complaint_by_hour.R
#
# Purpose: Create a line chart showing the number of complaints received per hour of the day.

# Load Required Libraries
library(arrow)      # For reading Parquet files
library(dplyr)      # Data manipulation
library(lubridate)  # Handling date-time
library(ggplot2)    # Visualization

# 1. Load the Dataset
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 2. Convert `created_date` to POSIXct (Ensure correct datetime format)
df <- df %>%
  mutate(created_datetime = as.POSIXct(created_date, format = "%Y-%m-%d %H:%M:%S"))

# 3. Extract the hour of the day
df <- df %>%
  mutate(hour_of_day = hour(created_datetime))

# 4. Aggregate Data: Count Complaints by Hour
hourly_complaints <- df %>%
  group_by(hour_of_day) %>%
  summarise(request_count = n(), .groups = "drop")

# 5. Create a Line Chart
p <- ggplot(hourly_complaints, aes(x = hour_of_day, y = request_count)) +
  geom_line(color = "blue", size = 1.2) +
  geom_point(color = "red", size = 2) + 
  labs(
    title = "Complaint Volume by Hour of the Day",
    x = "Hour of the Day (0-23)",
    y = "Number of Complaints"
  ) +
  scale_x_continuous(breaks = 0:23) +  # Show all hours on X-axis
  theme_minimal()

# 6. Print the Plot
print(p)

# 7. (Optional) Save the Plot as an Image
ggsave("complaints_by_hour.png", p, width = 10, height = 6)
