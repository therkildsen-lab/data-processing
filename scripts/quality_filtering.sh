#!/bin/bash

## This script is used to quality filter and trim poly g tails. It can process both paired end and single end data. 
SAMPLELIST=$1 # Path to a list of prefixes of the raw fastq files for paired end data, or a list of names of raw fastq files (with suffix) for single end data. It should be a subset of the the 1st column of the sample table.
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix (paired end) or the name (single end) of the raw fastq files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. An example of such a sample table is: /workdir/Backup/WhiteSturgeon/SampleLists/SampleTable.txt
BASEDIR=$3 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "AdapterClipped" and into which output files will be written to separate subdirectories. An example for the sturgeon data is: /workdir/Sturgeon/
PE=$4 # Whether the data is pair end or single end. true or false.

##### RUN EACH SAMPLE THROUGH PIPELINE #######

# Loop over each sample
for SAMPLEFILE in `cat $SAMPLELIST`; do

# Extract relevant values from a table of sample, sequencing, and lane ID (here in columns 4, 3, 2, respectively) for each sequenced library
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`

SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID  # When a sample has been sequenced in multiple lanes, we need to be able to identify the files from each run uniquely

SAMPLEADAPT=$BASEDIR'AdapterClipped/'$SAMPLE_SEQ_ID  # The output path and file prefix
SAMPLEQUAL=$BASEDIR'QualFiltered/'$SAMPLE_SEQ_ID  # The output path and file prefix


#### ADAPTER CLIPPING THE READS ####

# Trim polyg tail with fastp. Can also do quality and length trimming.
# -Q disables quality filter, -L disables length filter, -A disables adapter trimming
# Go to https://github.com/OpenGene/fastp for more information
if $PE; then
/programs/fastp/fastp --trim_poly_g -Q -L -A -i $SAMPLEADAPT'_AdapterClipped_F_paired.fastq.gz' -I SAMPLEADAPT'_AdapterClipped_R_paired.fastq.gz' -o $SAMPLEQUAL'_AdapterClipped_QualFiltered_F_paired.fastq.gz' -O $SAMPLEQUAL'_AdapterClipped_QualFiltered_R_paired.fastq.gz'
else
/programs/fastp/fastp --trim_poly_g -Q -L -A -i $SAMPLEADAPT'_AdapterClipped_SE.fastq.gz' -o $SAMPLEQUAL'_AdapterClipped_QualFiltered_SE.fastq.gz' 

fi

done
