#!/bin/bash

# This script is used to count per position depth for bam files.
BAMLIST=$1 # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv
BASEDIR=$2 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod

## Count per position depth per sample
samtools depth `cat $BAMLIST` > $BASEDIR'sample_lists/depth_per_position_per_sample.tsv'
## Convert depth to presence/absence
awk -v column_to_start=3 -f /workdir/data-processing/scripts/convert_count_to_presence.awk $BASEDIR'sample_lists/depth_per_position_per_sample.tsv' > $BASEDIR'sample_lists/presence_per_position_per_sample.tsv'
## Count sum of per position depth over all samples
awk -v column_to_start=3 -f /workdir/data-processing/scripts/sum_by_row.awk $BASEDIR'sample_lists/depth_per_position_per_sample.tsv' > $BASEDIR'sample_lists/depth_per_position_sum_over_all_samples.tsv'
## Count sum of per position presence over all samples
awk -v column_to_start=3 -f /workdir/data-processing/scripts/sum_by_row.awk $BASEDIR'sample_lists/presence_per_position_per_sample.tsv' > $BASEDIR'sample_lists/presence_per_position_sum_over_all_samples.tsv'
