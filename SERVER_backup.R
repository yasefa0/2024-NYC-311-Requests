# server.R
# Load Required Libraries
library(shiny)
library(arrow)
library(dplyr)
library(ggplot2)
library(lubridate)
library(shinycssloaders)
library(scales)
library(wordcloud)
library(RColorBrewer)
library(tidyr)

# Load Dataset with Arrow
file_path <- "/Users/yardo/College/WI 2025/BIS 412/NYC311/311-dataset-POSIXct.parquet"
nyc311_dataset <- open_dataset(file_path)

# Pre-compute hour aggregation at startup
hour_counts <- nyc311_dataset %>%
  select(created_date) %>%
  collect() %>%
  mutate(hour_of_day = hour(created_date)) %>%
  count(hour_of_day, name = "request_count")

# Pre-compute agency counts
agency_counts <- nyc311_dataset %>%
  group_by(agency) %>%
  summarise(requests = n()) %>%
  collect() %>%
  arrange(desc(requests)) %>%
  head(10)

# Pre-compute submission methods
submission_methods <- nyc311_dataset %>%
  filter(open_data_channel_type != "OTHER") %>%
  group_by(open_data_channel_type) %>%
  summarise(request_count = n()) %>%
  collect()

# Pre-compute complaints by month (for stacked time series)
complaints_by_month <- nyc311_dataset %>%
  select(created_date, complaint_type) %>%
  collect() %>%
  mutate(month = floor_date(created_date, "month")) %>%
  count(month, complaint_type) %>%
  group_by(complaint_type) %>%
  filter(sum(n) > 1000) %>%  # Only include complaint types with over 1000 occurrences
  ungroup()

# Pre-compute complaints by borough (for stacked bar chart)
complaints_by_borough <- nyc311_dataset %>%
  select(borough, complaint_type) %>%
  filter(borough != "") %>%
  collect() %>%
  count(borough, complaint_type) %>%
  group_by(complaint_type) %>%
  filter(sum(n) > 1000) %>%  # Only include complaint types with over 1000 occurrences
  ungroup() %>%
  group_by(borough) %>%
  mutate(total = sum(n)) %>%
  filter(n/total > 0.03) %>%  # Only include complaints that make up at least 3% in a borough
  ungroup()

# Pre-compute agency resolution times
agency_resolution_times <- nyc311_dataset %>%
  select(agency, created_date, closed_date) %>%
  filter(!is.na(closed_date)) %>%
  collect() %>%
  mutate(resolution_time_hours = as.numeric(difftime(closed_date, created_date, units = "hours"))) %>%
  filter(resolution_time_hours >= 0, resolution_time_hours < 720) %>%  # Filter out negative times and issues open longer than 30 days
  group_by(agency) %>%
  summarise(
    avg_resolution_hours = mean(resolution_time_hours, na.rm = TRUE),
    median_resolution_hours = median(resolution_time_hours, na.rm = TRUE),
    requests = n()
  ) %>%
  filter(requests > 100) %>%  # Only include agencies with over 100 requests
  arrange(avg_resolution_hours) %>%
  head(15)  # Top 15 fastest agencies for readability

shinyServer(function(input, output) {
  
  # Reactive function to generate plot data
  get_plot_data <- reactive({
    switch(input$plotType,
           "agency_barchart" = {
             agency_counts
           },
           "complaint_count_by_hour" = {
             hour_counts
           },
           "submission_methods" = {
             submission_methods
           },
           "wordcloud_descriptors" = {
             nyc311_dataset %>%
               select(descriptor) %>%
               head(100000) %>%
               collect() %>%
               mutate(descriptor = ifelse(is.na(descriptor), "", descriptor)) %>%
               count(descriptor) %>%
               filter(n > 50) %>%
               arrange(desc(n))
           },
           "stacked_time_series" = {
             complaints_by_month
           },
           "stacked_borough_bar" = {
             complaints_by_borough
           },
           "agency_resolution_time" = {
             agency_resolution_times
           },
           NULL
    )
  }) %>% bindCache(input$plotType)
  
  # Render the plot
  output$selectedPlot <- renderPlot({
    req(input$plotType)
    plot_data <- get_plot_data()
    
    switch(input$plotType,
           "agency_barchart" = {
             ggplot(plot_data, aes(x = reorder(agency, -requests), y = requests)) +
               geom_bar(stat = "identity") +
               labs(title = "Top 10 Agencies by Requests", x = "Agency", y = "Number of Requests") +
               theme_minimal() +
               theme(axis.text.x = element_text(angle = 45, hjust = 1))
           },
           "complaint_count_by_hour" = {
             ggplot(plot_data, aes(x = hour_of_day, y = request_count)) +
               geom_line(color = "blue", size = 1.2) +
               geom_point(color = "red", size = 2) +
               labs(title = "Complaint Volume by Hour of Day", 
                    x = "Hour of Day (0-23)", 
                    y = "Number of Requests") +
               scale_x_continuous(breaks = 0:23) +
               theme_minimal()
           },
           "submission_methods" = {
             max_value <- max(plot_data$request_count)
             breaks_seq <- seq(0, max_value, length.out = 6)
             
             ggplot(plot_data, aes(x = reorder(open_data_channel_type, request_count), 
                                   y = request_count, fill = open_data_channel_type)) +
               geom_bar(stat = "identity") +
               coord_flip() +
               labs(title = "Complaints by Submission Method",
                    x = "Submission Method",
                    y = "Number of Requests") +
               theme_minimal() +
               theme(legend.position = "none") +
               scale_y_continuous(labels = comma, breaks = breaks_seq)
           },
           "wordcloud_descriptors" = {
             wordcloud(
               words = plot_data$descriptor,
               freq = plot_data$n,
               min.freq = 2,
               max.words = 200,
               scale = c(3, 0.5),
               random.order = FALSE,
               rot.per = 0.25,
               colors = brewer.pal(8, "Dark2")
             )
           },
           "stacked_time_series" = {
             # Get top complaint types for better readability
             top_complaints <- plot_data %>%
               group_by(complaint_type) %>%
               summarise(total = sum(n)) %>%
               arrange(desc(total)) %>%
               head(10) %>%
               pull(complaint_type)
             
             # Filter for top complaints
             filtered_data <- plot_data %>%
               filter(complaint_type %in% top_complaints)
             
             ggplot(filtered_data, aes(x = month, y = n, fill = complaint_type)) +
               geom_area(position = "stack") +
               labs(title = "Trend of Top Complaint Types Over Time",
                    x = "Month",
                    y = "Number of Complaints",
                    fill = "Complaint Type") +
               theme_minimal() +
               theme(
                 legend.position = "bottom",
                 legend.title = element_text(size = 10),
                 legend.text = element_text(size = 8),
                 axis.text.x = element_text(angle = 45, hjust = 1)
               ) +
               scale_x_datetime(date_labels = "%b %Y", date_breaks = "2 month") +
               scale_y_continuous(labels = comma)
           },
           "stacked_borough_bar" = {
             # Get top complaint types for better readability
             top_complaints <- plot_data %>%
               group_by(complaint_type) %>%
               summarise(total = sum(n)) %>%
               arrange(desc(total)) %>%
               head(10) %>%
               pull(complaint_type)
             
             # Filter for top complaints and consolidate others
             filtered_data <- plot_data %>%
               mutate(complaint_type = ifelse(complaint_type %in% top_complaints, 
                                              complaint_type, "Other Complaints"))
             
             ggplot(filtered_data, aes(x = borough, y = n, fill = complaint_type)) +
               geom_bar(stat = "identity", position = "fill") +
               labs(title = "Proportion of Complaint Types by Borough",
                    x = "Borough",
                    y = "Proportion of Complaints",
                    fill = "Complaint Type") +
               theme_minimal() +
               theme(
                 legend.position = "bottom",
                 legend.title = element_text(size = 10),
                 legend.text = element_text(size = 8),
                 axis.text.x = element_text(angle = 45, hjust = 1)
               ) +
               scale_y_continuous(labels = percent_format())
           },
           "agency_resolution_time" = {
             ggplot(plot_data, aes(x = reorder(agency, -avg_resolution_hours), 
                                   y = avg_resolution_hours, fill = requests)) +
               geom_bar(stat = "identity") +
               geom_errorbar(aes(ymin = median_resolution_hours, 
                                 ymax = median_resolution_hours),
                             width = 0.5, color = "darkred") +
               labs(title = "Average Resolution Time by Agency (Top 15 Fastest)",
                    subtitle = "Red lines indicate median resolution time",
                    x = "Agency",
                    y = "Average Resolution Time (Hours)",
                    fill = "Number of\nRequests") +
               theme_minimal() +
               theme(
                 axis.text.x = element_text(angle = 45, hjust = 1),
                 legend.position = "right"
               ) +
               scale_fill_gradient(low = "lightblue", high = "darkblue")
           },
           NULL
    )
  }) %>% bindCache(input$plotType)
})