# Purpose: Generate a word cloud of the most common descriptors in your 311 dataset.
# Note: If "descriptor" contains multi-word text (e.g. "Loud Music/Party"), 
#       each phrase is treated as one "term" in this basic approach.

# 1. Load Libraries
library(arrow)       # for reading Parquet
library(dplyr)       # for data manipulation
library(wordcloud)   # for creating the word cloud

# 2. Read the Parquet File
df <- read_parquet("/Users/yardo/PycharmProjects/311-Requests/311-dataset.parquet")

# 3. Basic Cleaning: Replace any NA in 'descriptor' with empty string
df$descriptor[is.na(df$descriptor)] <- ""

# 4. Create Frequency Table
#    Each unique descriptor is treated as a "term"
descriptor_freq <- table(df$descriptor)

# 5. Generate Word Cloud
wordcloud(
  words = names(descriptor_freq),       # all unique descriptors
  freq = as.integer(descriptor_freq),   # their counts
  min.freq = 2,                         # minimum frequency to show
  max.words = 200,                      # max number of terms to plot
  scale = c(3, 0.5),                    # size range for largest vs. smallest
  random.order = FALSE,                 # plot higher freq words in the center
  rot.per = 0.25,                       # fraction of words rotated 90 degrees
  colors = brewer.pal(8, "Dark2")       # color palette
)
