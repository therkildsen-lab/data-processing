#!/bin/bash

# This script is used to count bam files after merging. These include deduplication and overlap clipping (paired-end data only)
BAMLIST=$1 # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv
BASEDIR=$2 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod

## Count per position depth per sample
samtools depth `cat $BAMLIST` > $BASEDIR'sample_lists/depth_per_position_per_sample.tsv'
## Convert depth to presence/absence
awk -f convert_count_to_presence.awk `cut --complement -f 1,2 $BASEDIR'sample_lists/depth_per_position_per_sample.tsv'` > $BASEDIR'sample_lists/presence_per_position_per_sample.tsv'
## Count sum of per position depth across samples
awk -f /workdir/data-processing/scripts/sum_by_row.awk `cut --complement -f 1,2 $BASEDIR'sample_lists/depth_per_position_per_sample.tsv'` > $BASEDIR'sample_lists/depth_per_position_all_samples.tsv'
## Count sum of per position depth across samples
awk -f /workdir/data-processing/scripts/sum_by_row.awk $BASEDIR'sample_lists/presence_per_position_per_sample.tsv' > $BASEDIR'sample_lists/presence_per_position_all_samples.tsv'
