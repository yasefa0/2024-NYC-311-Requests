
# 2. Aggregate Data: Find the Most Frequent Complaint Type per Agency
top_complaints <- df %>%
  group_by(agency, complaint_type) %>%
  summarise(request_count = n(), .groups = "drop") %>%
  arrange(desc(request_count)) %>%
  group_by(agency) %>%
  slice_max(order_by = request_count, n = 1) %>%  # Select the top complaint for each agency
  ungroup()

# 3. Create a Bar Chart
p <- ggplot(top_complaints, aes(x = reorder(agency, request_count), y = request_count, fill = complaint_type)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Most Frequent Complaint Type for Each Agency",
    x = "Agency Name",
    y = "Number of Complaints",
    fill = "Complaint Type"
  ) +
  theme_minimal()

# 4. Print the Plot
print(p)

# 5. (Optional) Save the Plot as an Image
ggsave("top_complaints_by_agency.png", p, width = 10, height = 6)
