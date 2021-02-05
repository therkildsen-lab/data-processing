#!/bin/bash

## This script is used to count per position depth for bam files. It will create one depth file per bam file.
# Advantage of this version is that you can use R to process the depth files.
BAMLIST=$1 # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv
JOBS=${2:-1}
MINBASEQ=${3:-20}
MINMAPQ=${4:-20}
SAMTOOLS=${5:-samtools}

JOB_INDEX=0

for SAMPLEBAM in `cat $BAMLIST`; do
	## Count per position depth per sample
	$SAMTOOLS depth -aa $SAMPLEBAM -q $MINBASEQ -Q $MINMAPQ | cut -f 3 | gzip > $SAMPLEBAM'.depth.gz' &
	
	JOB_INDEX=$(( JOB_INDEX + 1 ))
	if [ $JOB_INDEX == $JOBS ]; then
		wait
		JOB_INDEX=0
	fi
done