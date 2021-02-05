## This script is used to summarize all the individual bam depth files, 
# It will come up with summary statistics for each individual as well per position depth and presence/absence summed across all individuals

args <- commandArgs(trailingOnly = TRUE)
BAMLIST <- args[1] # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv
SAMPLETABLE <- args[2] # Path to a sample table where the 1st column is the prefix of the MERGED bam files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The 5th column is population name and 6th column is the data type. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table_merged.tsv
BASEDIR <- args[3] # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod/

library(tidyverse)
library(data.table)
bam_list <- read_tsv(BAMLIST, col_names = F)$X1
bam_list_prefix <- str_extract(BAMLIST, "[^.]+")
sample_table <- read_tsv(SAMPLETABLE)
for (i in 1:length(bam_list)){
  print(i)
  print(pryr::mem_used())
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
write_tsv(output, paste0(bam_list_prefix, "_depth_per_position_per_sample_summary.tsv"))
write_lines(total_depth, paste0(bam_list_prefix, "_depth_per_position_all_samples.txt"))
write_lines(total_presence, paste0(bam_list_prefix, "_presence_per_position_all_samples.txt"))

# Total Depth per Site across All Individuals (on server)
total_depth <- fread(paste0(bam_list_prefix, "_depth_per_position_all_samples.txt"))
total_presence <- fread(paste0(bam_list_prefix, "_presence_per_position_all_samples.txt"))
total_depth_summary <- count(total_depth, by=V1)
total_presence_summary <- count(total_presence, by=V1)
write_tsv(total_depth_summary, paste0(bam_list_prefix, "_depth_per_position_all_samples_histogram.tsv"))
write_tsv(total_presence_summary, paste0(bam_list_prefix, "_presence_per_position_all_samples_histogram.tsv"))
