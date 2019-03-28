args <- commandArgs(trailingOnly = TRUE)
BAMLIST <- args[1]
SAMPLETABLE <- args[2]
BASEDIR <- args[3]

library(tidyverse)
library(data.table)
bam_list <- read_tsv(BAMLIST, col_names = F)$X1
sample_table <- read_tsv(SAMPLETABLE)
for (i in 1:3){
  print(i)
  depth <- fread(paste0(bam_list[i], ".depth"))$V1
  mean_depth <- mean(depth)
  sd_depth <- sd(depth)
  presence <- as.logical(depth)
  proportion_of_reference_covered <- mean(presence)
  if (i==1){
    output <- data.frame(sample_seq_id=sample_table[i,1], mean_depth, sd_depth, proportion_of_reference_covered)
    total_depth <- depth
    total_presence <- presence
  } else {
    output <- rbind(output, cbind(sample_seq_id=sample_table[i,1], mean_depth, sd_depth, proportion_of_reference_covered))
    total_depth <- total_depth + depth
    total_presence <- total_presence + presence
  }
}
write_tsv(output, paste0(BASEDIR, "sample_lists/depth_per_position_per_sample.tsv"))
write_lines(total_depth, paste0(BASEDIR, "sample_lists/depth_per_position_all_samples.txt"))
write_lines(total_presence, paste0(BASEDIR, "sample_lists/presence_per_position_all_samples.txt"))

# Total Depth per Site across All Individuals (on server)
total_depth <- fread(paste0(BASEDIR, "sample_lists/depth_per_position_all_samples.txt"))
total_presence <- fread(paste0(BASEDIR, "sample_lists/presence_per_position_all_samples.txt"))
total_depth_summary <- count(total_depth, by=V1)
total_presence_summary <- count(total_presence, by=V1)
write_tsv(total_depth_summary, paste0(BASEDIR, "sample_lists/depth_per_position_all_samples_summary.tsv"))
write_tsv(total_presence_summary, paste0(BASEDIR, "sample_lists/presence_per_position_all_samples_summary.tsv"))
