#!/bin/bash

## This script is used to count per position depth for bam files. It will create one depth file per bam file.
# Advantage of this version is that you can use R to process the depth files.
BAMLIST=$1 # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv

for SAMPLEBAM in `cat $BAMLIST`; do
	## Count per position depth per sample
	samtools depth -aa $SAMPLEBAM | cut -f 3 > $SAMPLEBAM'.depth'
done